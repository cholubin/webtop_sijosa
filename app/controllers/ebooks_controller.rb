# encoding: utf-8

class EbooksController < ApplicationController
  def index
    
    @menu = "ebook"
    @board = "ebook"
    @section = "index"
  
    @ebooks = Ebook.all()
    @ebooks = @ebooks.search(params[:search], params[:page])      
    
    @categories = Category.all(:gubun => "ebook", :order => [:priority])

    render 'ebook'
  end

  def show
    @menu = "ebook"      
    @board = "ebook"
    @section = "show"
      
    @ebook = Ebook.get(params[:id])
    
    if @ebook.common == false
      if @ebook.user_id == current_user.id
        render 'ebook'
      else
        redirect_to '/'
      end
    else
      render 'ebook'
    end

  end


end
