SELECT
    ca_ref.ca_state AS refunded_state,
    ca_ret.ca_state AS returning_state,
    d.d_year,
    d.d_moy AS month,
    SUM(cr.cr_net_loss) AS total_net_loss,
    SUM(cr.cr_return_amount) AS total_return_amount,
    AVG(cr.cr_return_tax) AS avg_return_tax,
    SUM(inv.inv_quantity_on_hand) AS total_inventory_on_hand,
    COUNT(DISTINCT cr.cr_order_number) AS distinct_orders,
    SUM(CASE WHEN ca_ret.ca_state <> ca_ref.ca_state THEN 1 ELSE 0 END) AS cross_state_returns,
    RANK() OVER (ORDER BY SUM(cr.cr_net_loss) DESC) AS net_loss_rank
FROM catalog_returns cr
JOIN date_dim d
  ON cr.cr_returned_date_sk = d.d_date_sk
JOIN customer_address ca_ref
  ON cr.cr_refunded_addr_sk = ca_ref.ca_address_sk
JOIN customer_address ca_ret
  ON cr.cr_returning_addr_sk = ca_ret.ca_address_sk
LEFT JOIN inventory inv
  ON inv.inv_date_sk = d.d_date_sk
WHERE
    cr.cr_return_tax > 0
    AND d.d_year = 2001
    AND ca_ref.ca_country = 'United States'
    AND ca_ret.ca_country = 'United States'
GROUP BY
    ca_ref.ca_state,
    ca_ret.ca_state,
    d.d_year,
    d.d_moy
HAVING
    SUM(cr.cr_net_loss) > 0
ORDER BY
    total_net_loss DESC
LIMIT 100
