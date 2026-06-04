class ReportsController < ApplicationController
  def create
    @target = User.find(params[:id])
    Report.create!(
      reporter: Current.user,
      reported: @target,
      reason: params[:reason].presence || :other,
      note: params[:note]
    )

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_back fallback_location: root_path, notice: "Reported — thank you." }
    end
  end
end
