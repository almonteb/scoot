require 'digest/sha1'

class User < ActiveRecord::Base
  has_many :projects
  has_many :committerships
  has_many :repositories, :through => :committerships
  has_many :ssh_keys, :order => "id desc"
  has_many :comments
  has_many :events, :order => "events.created_at asc", :dependent => :destroy
  
  # Virtual attribute for the unencrypted password
  attr_accessor :password, :current_password

  attr_protected :login

  validates_presence_of     :login, :email,               :if => :password_required?
  validates_format_of       :login, :with => /^[a-z0-9\-_\.]+$/i
  validates_format_of       :email, :with => /^[^@\s]+@([\-a-z0-9]+\.)+[a-z]{2,}$/i
  validates_presence_of     :password,                   :if => :password_required?
  validates_presence_of     :password_confirmation,      :if => :password_required?
  validates_length_of       :password, :within => 4..40, :if => :password_required?
  validates_confirmation_of :password,                   :if => :password_required?
  validates_length_of       :login,    :within => 3..40
  validates_length_of       :email,    :within => 3..100
  validates_uniqueness_of   :login, :email, :case_sensitive => false

  before_save :encrypt_password
  before_create :activate
  before_validation :lint_identity_url
  
  define_index do
    indexes login
  end

  def self.find_by_login!(name)
    find_by_login(name) || raise(ActiveRecord::RecordNotFound)
  end

  # Authenticates a user by their login name and unencrypted password.  Returns the user or nil.
  def self.authenticate(email, password)
    u = find :first, :conditions => ['email = ? and activated_at IS NOT NULL', email] # need to get the salt
    u && u.authenticated?(password) ? u : nil
  end

  # Encrypts some data with the salt.
  def self.encrypt(password, salt)
    Digest::SHA1.hexdigest("--#{salt}--#{password}--")
  end

  def self.generate_random_password(password_size = 12)
    characters = (("a".."z").to_a + ("0".."9").to_a) - %w[0 o i l 1]
    (0...password_size).collect do |char|
      characters[rand(characters.length)]
    end.join
  end
  
  def validate
    if !not_openid?
      begin
        OpenIdAuthentication.normalize_url(self.identity_url)
      rescue OpenIdAuthentication::InvalidOpenId => e
        errors.add(:identity_url, "Invalid url")
      end
    end
  end
  
  # Activates the user in the database.
  def activate
    @activated = true
    self.attributes = {:activated_at => Time.now.utc, :activation_code => nil}
    save(false)
  end

  def activated?
    # the existence of an activation code means they have not activated yet
    activation_code.nil?
  end

  # Returns true if the user has just been activated.
  def recently_activated?
    @activated
  end

  # Encrypts the password with the user salt
  def encrypt(password)
    self.class.encrypt(password, salt)
  end

  def authenticated?(password)
    crypted_password == encrypt(password)
  end

  def remember_token?
    remember_token_expires_at && Time.now.utc < remember_token_expires_at
  end

  # These create and unset the fields required for remembering users between browser closes
  def remember_me
    remember_me_for 2.weeks
  end

  def remember_me_for(time)
    remember_me_until time.from_now.utc
  end

  def remember_me_until(time)
    self.remember_token_expires_at = time
    self.remember_token            = encrypt("#{email}--#{remember_token_expires_at}")
    save(false)
  end

  def forget_me
    self.remember_token_expires_at = nil
    self.remember_token            = nil
    save(false)
  end

  def reset_password!
    generated = User.generate_random_password
    self.password = generated
    self.password_confirmation = generated
    self.save!
    generated
  end

  def can_write_to?(repository)
    !!committerships.find_by_repository_id(repository.id)
  end

  def to_param
    login
  end

  def to_xml(opts = {})
    super({:except => [:activation_code, :crypted_password, :remember_token, :remember_token_expires_at, :salt, :ssh_key_id]}.merge(opts))
  end
  
  protected
    # before filter
    def encrypt_password
      return if password.blank?
      self.salt = Digest::SHA1.hexdigest("--#{Time.now.to_s}--#{login}--") if new_record?
      self.crypted_password = encrypt(password)
    end

    def password_required?
      not_openid? && (crypted_password.blank? || !password.blank?)
    end

    def not_openid?
      identity_url.blank?
    end

    def make_activation_code
      self.activation_code = Digest::SHA1.hexdigest( Time.now.to_s.split(//).sort_by {rand}.join )
    end
    
    def lint_identity_url
      return if not_openid?
      self.identity_url = OpenIdAuthentication.normalize_url(self.identity_url)
    rescue OpenIdAuthentication::InvalidOpenId
      # validate will catch it instead
    end
end
