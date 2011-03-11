# encoding: utf-8

class SharedimagesController < ApplicationController
    before_filter :authenticate_user!  
  # GET /myimages
  # GET /myimages.xml
  def index
    
    #확장자별 소팅
    ext = params[:ext]
    folder = params[:folder]
    
    category = params[:cate]
    subcategory = params[:subcate]
    
    @menu = "sharedimage"
    @board = "sharedimage"
    @section = "index"
  
    if ext == "all" or ext == nil or ext == ""
      ext = "all"
    end
    
    if ext == "all" and folder == "all"
      @sharedimages = Sharedimage.all(:open_fl => true, :order => [:created_at.desc])                   
    elsif ext == "all" and folder != "all"
      @sharedimages = Sharedimage.all( :open_fl => true, :order => [:created_at.desc])
    elsif ext != "all" and folder == "all"
      @sharedimages = Sharedimage.all(:type => ext, :open_fl => true, :order => [:created_at.desc])
    elsif ext != "all" and folder != "all"
      @sharedimages = Sharedimage.all( :type => ext, :open_fl => true, :order => [:created_at.desc])
    end
    
    if category != nil and category != ""
      if subcategory != nil and subcategory != ""
        @sharedimages = @sharedimages.all(:category => category.to_i, :subcategory => subcategory.to_i)
      else
        @sharedimages = @sharedimages.all(:category => category.to_i)
      end
    end
    
    @sharedimages = @sharedimages.search_user(params[:search], params[:page])
    @categories = Category.all(:gubun => "image", :order => [:priority])

    @category = category
    @subcategory = subcategory
    
    render 'sharedimage'
    
    
  end

  # GET /myimages/1
  # GET /myimages/1.xml
  def show
    
    if signed_in?
      @menu = "sharedimage"      
      @board = "sharedimage"
      @section = "show"
        
      @sharedimage = Sharedimage.get(params[:id].to_i)
      @categories = Category.all(:gubun => "image", :order => [:priority])
      
        render 'sharedimage'

    else
      redirect_to '/login'
    end
  end

  # GET /myimages/new
  # GET /myimages/new.xml
  def new
    @menu = "sharedimage"    
    @board = "sharedimage"
    @section = "new"
    
    @sharedimage = Sharedimage.new
  
    
    if Folder.first(:user_id => current_user.id.to_s, :name => "photo") == nil
      @folder = Folder.new()
      @folder.name = "photo"
      @folder.user_id = current_user.id
      @folder.save
    end

    @folders = Folder.all(:open_fl => true,:name.not => "basic_photo" )
      
    render 'sharedimage'
  end

  # GET /myimages/1/edit
  def edit
    @sharedimage = Sharedimage.get(params[:id])

    @menu = "sharedimage"    
    @board = "sharedimage"
    @section = "edit"

    @folders = Folder.all(:user_id => current_user.id)
        
    render 'sharedimage'    
  end

  # POST /myimages
  # POST /myimages.xml
  def create
    @menu = "sharedimage"    
    @board = "sharedimage"
    @section = "new"
    
    @sharedimage = Sharedimage.new(params[:myimage])
    @sharedimage.user_id = current_user.id
    
    image_path = @sharedimage.image_path
    SharedimageUploader.store_dir = @sharedimage.image_path
    
    puts_message "dir::::>" + @sharedimage.image_path
    # 이미지 업로드 처리 ===============================================================================
    if params[:myimage][:image_file] != nil

      @sharedimage.image_file = params[:myimage][:image_file]      
      @temp_filename = sanitize_filename(params[:myimage][:image_file].original_filename)


      # 중복파일명 처리 ===============================================================================
      while File.exist?(image_path + "/" + @temp_filename) 
        ext_name = File.extname(@temp_filename)
        file_name = @temp_filename.gsub(ext_name,'')

        @temp_filename = file_name + "_1" + ext_name
        @sharedimage.image_filename = @temp_filename
        
        puts image_path + "/" + @temp_filename
      end 

      ext_name = File.extname(@temp_filename)      
      file_name = @temp_filename.gsub(ext_name,'')
      #검색시 필터로 사용할 타입 설정
      @sharedimage.type = ext_name.gsub(".",'').downcase
       
      @sharedimage.image_filename = @temp_filename
      
      if ext_name == ".eps" or ext_name == ".pdf"
        @sharedimage.image_thumb_filename = file_name + ".png"
      else
        @sharedimage.image_thumb_filename = file_name + ".jpg"
      end
       # 중복파일명 처리 ===============================================================================

      @sharedimage.image_filename_encoded = @sharedimage.image_file.filename

      if params[:myimage][:name] == ""
        @sharedimage.name = file_name
      end

      if params[:myimage][:folder] == ""
        @sharedimage.folder = "photo"
      else
        @sharedimage.folder = params[:myimage][:folder]
      end
      puts_message @sharedimage.folder
      
      if @sharedimage.save  
         # image filename renaming ======================================================================

         ext_name_up = File.extname(@sharedimage.image_filename_encoded)
         file_name_up = @sharedimage.image_filename_encoded.gsub(ext_name_up,'')
         
         
        if (file_name_up + ext_name_up)
          if  File.exist?(image_path + "/" + file_name_up + ext_name_up)
            if params[:myimage][:folder] == "photo"
          	  File.rename image_path + "/" + @sharedimage.image_filename_encoded, image_path  + "/" + file_name + ext_name #original file
          	  
          	  if ext_name_up == ".eps" or ext_name_up == ".pdf"
          	    puts %x[#{RAILS_ROOT}"/lib/thumbup" #{image_path + "/" + @sharedimage.image_filename} #{image_path + "/preview/" + file_name + ".png"} 0.5 #{image_path + "/thumb/" + file_name + ".png"} 128]            	  
          	  else
          	    puts %x[#{RAILS_ROOT}"/lib/thumbup" #{image_path + "/" + @sharedimage.image_filename} #{image_path + "/preview/" + file_name + ".jpg"} 0.5 #{image_path + "/thumb/" + file_name + ".jpg"} 128]            	  
        	    end
          	else
          	  image_folder = @sharedimage.image_folder(params[:myimage][:folder])
          	  File.rename image_path + "/" + @sharedimage.image_filename_encoded, image_folder  + "/" + file_name + ext_name #original file
          	  if ext_name_up == ".eps" or ext_name_up == ".pdf"
          	    puts %x[#{RAILS_ROOT}"/lib/thumbup" #{image_folder + "/" + @sharedimage.image_filename} #{image_folder + "/preview/" + file_name + ".png"} 0.5 #{image_folder + "/thumb/" + file_name + ".png"} 128]            	  
          	  else
          	    puts %x[#{RAILS_ROOT}"/lib/thumbup" #{image_folder + "/" + @sharedimage.image_filename} #{image_folder + "/preview/" + file_name + ".jpg"} 0.5 #{image_folder + "/thumb/" + file_name + ".jpg"} 128]            	  
          	  end
          	end
          end
        end      
         # image filename renaming ======================================================================
         redirect_to myimages_path
       else
         render 'sharedimage'
       end

    else
          flash[:notice] = '이미지는 반드시 선택하셔야 합니다.'      
          
          render 'sharedimage'
    end
      
      # SharedimageUploader.store_dir = @sharedimage.image_path

  end

  # PUT /myimages/1
  # PUT /myimages/1.xml
  def update
    
    #레이아웃 관련 변수 
    @menu = "sharedimage"    
    @board = "sharedimage"
    @section = "edit"

    #페이징 관련 변수 
    search = params[:search]
    ext = params[:ext]

    #모델관련 변수 
    @sharedimage = Sharedimage.get(params[:id])
    @sharedimage.name = params[:myimage][:name]
    @sharedimage.open_fl = params[:myimage][:open_fl]
    @sharedimage.description = params[:myimage][:description]
    new_folder_name = params[:myimage][:folder]
    old_folder_name = @sharedimage.folder
    @sharedimage.folder = new_folder_name
    
    image_path_basic = @sharedimage.image_path                          # 기본 이미지폴더 (photo)
    image_path_new_folder = @sharedimage.image_folder(new_folder_name)  # 변경될 폴더 
    image_path_old_folder = @sharedimage.image_folder(old_folder_name)  # 기존 폴더     
    
          
    ext_name = File.extname(@sharedimage.image_filename)
    file_name = @sharedimage.image_filename.gsub(ext_name,'')

    #파일명의 확장자로 판단하여 타입결정
    @sharedimage.type = ext_name.gsub('.','').downcase

    #이미지를 변경하는 경우 
    if params[:myimage][:image_file] != nil
      #먼저 기존에 업로드된 이미지를 삭제한다.
      if !@sharedimage.image_path.nil? && !@sharedimage.image_filename.nil?
        if  File.exist?(image_path_old_folder + "/" + @sharedimage.image_filename)
          #오리지날 파일 삭제
      	  File.delete(image_path_old_folder + "/" + @sharedimage.image_filename)         #original image file      
      	  # 썸네일 삭제
      	  if File.exist?(image_path_old_folder + "/thumb/" + @sharedimage.image_filename)
      	    File.delete(image_path_old_folder + "/thumb/" + @sharedimage.image_filename)         #original image file
      	  end
      	  # 프리뷰 삭제
      	  if File.exist?(image_path_old_folder + "/preview/" + @sharedimage.image_filename)
            File.delete(image_path_old_folder + "/preview/" + @sharedimage.image_filename)   #thumbnail image file  	  
          end
      	end
    	end
    	
    	#새로운 이미지파일을 업로드 한다.
      @sharedimage.image_file = params[:myimage][:image_file]      
      @temp_filename = sanitize_filename(params[:myimage][:image_file].original_filename)

      # 중복파일명 처리 ===============================================================================
      # 중복체크는 기본폴더(photo)에서 한 후 목표 폴더로 이동처리 한다. (캐리어웨이브 제약조건 때문.)
      while File.exist?(image_path_basic + "/" + @temp_filename) 
        @temp_filename = @temp_filename.gsub(File.extname(@temp_filename),"") + "_1" + File.extname(@temp_filename)
        @sharedimage.image_filename = @temp_filename
      end 
      @sharedimage.image_filename = @temp_filename
      @sharedimage.image_thumb_filename = @temp_filename
      # 중복파일명 처리 ===============================================================================

      @sharedimage.image_filename_encoded = @sharedimage.image_file.filename    	
    end

    if @sharedimage.save
      if @temp_filename != nil
        file_name = @sharedimage.image_filename.gsub(File.extname(@temp_filename),"")
      else
        file_name = @sharedimage.image_filename.gsub(ext_name,"")        
      end

      #파일을 새롭게 업로드하는 경우 
      if params[:myimage][:image_file] != nil
    	  File.rename image_path_basic + "/" + @sharedimage.image_filename_encoded, image_path_new_folder  + "/" + @sharedimage.image_filename #original file
    	  #썸네일생성 
    	  puts %x[#{RAILS_ROOT}"/lib/thumbup" #{image_path_new_folder + "/" + @sharedimage.image_filename} #{image_path_new_folder + "/preview/" + file_name + ".jpg"} 0.5 #{image_path_new_folder + "/thumb/" + file_name + ".jpg"} 128]            	  

      #폴더만 변경하는 경우 
      else
        puts "====================================================================="
        puts image_path_old_folder + "/" + @sharedimage.image_filename
        puts "====================================================================="        
    	  File.rename image_path_old_folder + "/" + @sharedimage.image_filename, image_path_new_folder  + "/" + @sharedimage.image_filename #original file
    	  File.rename image_path_old_folder + "/Preview/" + file_name + ".jpg", image_path_new_folder  + "/Preview/" + file_name + ".jpg" #original file
    	  File.rename image_path_old_folder + "/Thumb/" + file_name + ".jpg", image_path_new_folder  + "/Thumb/" + file_name + ".jpg" #original file
      end
      
      redirect_to '/myimages?search='+search+'&ext='+ext
    else
      render 'sharedimage'
    end


  end

  # DELETE /myimages/1
  # DELETE /myimages/1.xml
  def destroy
    @sharedimage = Sharedimage.get(params[:id])
    
    image_path = @sharedimage.image_folder(@sharedimage.folder)
    
    if !image_path.nil? && !@sharedimage.image_filename.nil?
      if  File.exist?(image_path + "/" + @sharedimage.image_filename)
      
        #오리지날 파일 삭제
    	  File.delete(image_path + "/" + @sharedimage.image_filename)         #original image file      
  	  
    	  # 썸네일 삭제
    	  if File.exist?(image_path + "/thumb/" + @sharedimage.image_filename)
    	    File.delete(image_path + "/thumb/" + @sharedimage.image_filename)         #original image file
    	  end
    	  # 프리뷰 삭제
    	  if File.exist?(image_path + "/preview/" + @sharedimage.image_filename)
          File.delete(image_path + "/preview/" + @sharedimage.image_filename)   #thumbnail image file  	  
        end
    	end
  	end
    @sharedimage.destroy

    respond_to do |format|
      format.html { redirect_to(myimages_url) }
      format.xml  { head :ok }
    end
  end
  
  def deleteSelection
     chk = params[:ids].split(',')

     if !chk.nil? 

       chk.each do |c|
         @sharedimage = Sharedimage.get(c.to_i)

         image_path = @sharedimage.image_folder(@sharedimage.folder)

         if !image_path.nil? && !@sharedimage.image_filename.nil?
           if  File.exist?(image_path + "/" + @sharedimage.image_filename)
             #오리지날 파일 삭제
         	  File.delete(image_path + "/" + @sharedimage.image_filename)         #original image file      

         	  # 썸네일 삭제
         	  if File.exist?(image_path + "/thumb/" + @sharedimage.image_filename)
         	    File.delete(image_path + "/thumb/" + @sharedimage.image_filename)         #original image file
         	  end
         	  # 프리뷰 삭제
         	  if File.exist?(image_path + "/preview/" + @sharedimage.image_filename)
               File.delete(image_path + "/preview/" + @sharedimage.image_filename)   #thumbnail image file  	  
            end
         	end
       	end

         @sharedimage.destroy
       end
      end

      @sharedimages = Sharedimage.all(:open_fl => true, :order => [:created_at.desc]).search(params[:search], params[:page])   

      render :update do |page|
        page.replace_html 'myimage_partial', :partial => 'myimage_partial', :object => @sharedimages
      end     
  end

  def change_open_status
    id = params[:id].to_i
    myimage = Sharedimage.get(id)
    
    puts_message myimage.open_fl.to_s
    
    if myimage.open_fl == true
      myimage.open_fl = false
      render_str =  "cancel_share"
    else
      myimage.open_fl = true
      render_str =  "share"
    end
    
    if myimage.save 
      render :text => render_str
    else
      render :text => "fail"
    end
    
  end
end
