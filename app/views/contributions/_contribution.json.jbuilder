json.extract! contribution, :id, :amount, :effective_from, :block, :description, :active, :created_at, :updated_at
json.url contribution_url(contribution, format: :json)
json.formatted_amount number_to_currency(contribution.amount, unit: "Rp. ", separator: ",", delimiter: ".")
json.block_display contribution.block || "All Blocks"
json.status do
  if contribution.active?
    if contribution.effective_from <= Date.current
      json.label "Active"
      json.class "success"
    else
      json.label "Future"
      json.class "warning"
    end
  else
    json.label "Inactive"
    json.class "secondary"
  end
end