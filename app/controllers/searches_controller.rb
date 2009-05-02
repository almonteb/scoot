class SearchesController < ApplicationController
  
  def show
    unless params[:q].blank?
      @results = ThinkingSphinx::Search.search(params[:q])
    end
  end
  
end
