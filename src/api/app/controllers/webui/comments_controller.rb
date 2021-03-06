class Webui::CommentsController < Webui::WebuiController
  before_action :require_login
  before_action :find_commentable, only: :create

  def create
    comment = @commented.comments.new(permitted_params)
    User.session!.comments << comment
    @commentable = comment.commentable

    status = if comment.save
               flash.now[:success] = 'Comment created successfully.'
               :ok
             else
               flash.now[:error] = "Failed to create comment: #{comment.errors.full_messages.to_sentence}."
               :unprocessable_entity
             end
    render(partial: 'webui/comment/comment_list', locals: { commentable: @commentable }, status: status)
  end

  def destroy
    comment = Comment.find(params[:id])
    authorize comment, :destroy?
    @commentable = comment.commentable

    status = if comment.blank_or_destroy
               flash.now[:success] = 'Comment deleted successfully.'
               :ok
             else
               flash.now[:error] = "Failed to delete comment: #{comment.errors.full_messages.to_sentence}."
               :unprocessable_entity
             end
    render(partial: 'webui/comment/comment_list', locals: { commentable: @commentable }, status: status)
  end

  private

  def permitted_params
    params.require(:comment).permit(:body, :parent_id)
  end

  def find_commentable
    commentable = [Project, Package, BsRequest].find { |klass| klass.name == params[:commentable_type] }

    if commentable.nil?
      redirect_to(root_path, error: 'Failed to create comment')
    else
      @commented = commentable.find(params[:commentable_id])
    end
  end
end
