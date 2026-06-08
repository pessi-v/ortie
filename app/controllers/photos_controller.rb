class PhotosController < ApplicationController
  def create
    unless nsfw_available?
      redirect_to settings_path(anchor: "photos-section"), alert: "Photo uploads are paused right now — please try again later."
      return
    end

    if Current.user.photos.count >= Photo::MAX_PER_USER
      redirect_to settings_path(anchor: "photos-section"), alert: "You already have the maximum of #{Photo::MAX_PER_USER} photos."
      return
    end

    @photo = Current.user.photos.new(photo_params.merge(position: next_position))

    if @photo.save
      ProcessPhotoJob.perform_later(@photo)
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to settings_path(anchor: "photos-section") }
      end
    else
      redirect_to settings_path(anchor: "photos-section"), alert: @photo.errors.full_messages.to_sentence
    end
  end

  def destroy
    photo = Current.user.photos.find(params[:id])
    photo.destroy
    reindex_positions
    redirect_to settings_path(anchor: "photos-section")
  end

  def make_primary
    photo = Current.user.photos.find(params[:id])
    others = Current.user.photos.where.not(id: photo.id).order(:position).to_a

    ActiveRecord::Base.transaction do
      ActiveRecord::Base.connection.execute("SET CONSTRAINTS photos_user_position_unique DEFERRED")
      ([photo] + others).each_with_index { |p, i| p.update_columns(position: i + 1) }
    end

    redirect_to settings_path(anchor: "photos-section"), notice: "Primary photo updated."
  end

  private

  def photo_params
    params.expect(photo: %i[image])
  end

  def next_position
    (Current.user.photos.maximum(:position) || 0) + 1
  end

  # Compact remaining photos to contiguous 1..n (ascending order is collision-free).
  def reindex_positions
    Current.user.photos.order(:position).each_with_index do |photo, i|
      photo.update_columns(position: i + 1) unless photo.position == i + 1
    end
  end
end
