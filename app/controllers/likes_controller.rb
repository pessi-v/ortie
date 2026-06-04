class LikesController < ApplicationController
  before_action :set_target

  # like or pass — kind comes from the route default
  def create
    @kind = params[:kind]
    @result = RecordLike.new(
      actor: Current.user, target: @target, kind: @kind, intro_note: params[:intro_note]
    ).call

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_back fallback_location: root_path, notice: html_notice }
    end
  end

  # un-pass: drop the pass edge so they return to New profiles
  def destroy
    Like.where(liker_id: Current.user.id, liked_id: @target.id, kind: :pass).destroy_all

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_back fallback_location: passed_path, notice: "Un-passed." }
    end
  end

  private

  def set_target
    @target = User.find(params[:id])
  end

  def html_notice
    return "It's a match!" if @result&.matched

    @kind == "pass" ? "Passed." : "Liked."
  end
end
