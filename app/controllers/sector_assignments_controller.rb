class SectorAssignmentsController < ApplicationController
  def update
    stock = Stock.find(params[:stock_id])
    SectorAssignmentService.new(
      stock: stock,
      sector_id: sector_params[:sector_id],
      new_sector_name: sector_params[:new_sector_name]
    ).call

    redirect_back fallback_location: root_path, notice: "섹터를 변경했습니다."
  end

  private

  def sector_params
    params.permit(:sector_id, :new_sector_name)
  end
end
