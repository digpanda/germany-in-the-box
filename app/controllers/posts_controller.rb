class PostsController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :set_post, only: [:show, :edit, :update, :destroy]
  before_action :base64_to_uploadedfile, only: [:create, :update]
  # GET /posts
  # GET /posts.json
  def index
    @posts = Post.all
  end

  # GET /posts/1
  # GET /posts/1.json
  def show
  end

  # GET /posts/new
  def new
    @post = Post.new
  end

  # GET /posts/1/edit
  def edit
  end

  # POST /posts
  # POST /posts.json
  def create
    @owner = User.find(post_params[:owner])
    @post = Post.new(post_params)
    @owner.posts.push(@post)

    respond_to do |format|
      if @post.save
        format.html { redirect_to @post, notice: 'Post was successfully created.' }
        format.json { render :show, status: :created, location: @post }
      else
        format.html { render :new }
        format.json { render json: @post.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /posts/1
  # PATCH/PUT /posts/1.json
  def update
    respond_to do |format|
      if @post.update(post_params)
        format.html { redirect_to @post, notice: 'Post was successfully updated.' }
        format.json { render :show, status: :ok, location: @post }
      else
        format.html { render :edit }
        format.json { render json: @post.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /posts/1
  # DELETE /posts/1.json
  def destroy
    @post.destroy
    respond_to do |format|
      format.html { redirect_to posts_url, notice: 'Post was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_post
    @post = Post.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def post_params
    params.require(:post).permit(:name, :image, :productId, :owner, :collectionId, :chatId)
  end

  def base64_to_uploadedfile
    base64 = params[:post][:base64]
    
    if base64
      base64_code = base64[:code]
      base64_original_filename = base64[:original_filename]
 
      tempfile = Tempfile.new(SecureRandom.hex(16).to_s)
      tempfile.binmode
      tempfile.write(Base64.decode64(base64_code))

      params[:post][:image] = ActionDispatch::Http::UploadedFile.new(:tempfile => tempfile, :filename => base64_original_filename, :original_filename => base64_original_filename); 
    end
  end
end
