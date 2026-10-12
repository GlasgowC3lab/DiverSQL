WITH sampled_item AS (
    SELECT *
    FROM item TABLESAMPLE BERNOULLI (10)
)
SELECT
    ss.ss_ticket_number,
    d_sale.d_date AS sale_date,
    d_return.d_date AS return_date,
    i.i_item_id,
    i.i_units,
    i.i_class,
    p.p_promo_name,
    ws.web_name,
    cp.cp_department,
    hd.hd_buy_potential,
    ca.ca_state,
    inv.inv_quantity_on_hand,
    sr.sr_return_quantity,
    sr.sr_return_amt,
    ss.ss_ext_sales_price,
    ROW_NUMBER() OVER (PARTITION BY ss.ss_store_sk ORDER BY ss.ss_ext_sales_price DESC) AS rn_per_store,
    RANK() OVER (ORDER BY ss.ss_ext_sales_price DESC) AS global_sales_rank
FROM store_sales ss
JOIN date_dim d_sale ON ss.ss_sold_date_sk = d_sale.d_date_sk
JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
JOIN sampled_item i ON ss.ss_item_sk = i.i_item_sk
JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
JOIN web_site ws ON ws.web_open_date_sk = d_sale.d_date_sk
JOIN catalog_page cp ON cp.cp_start_date_sk = d_sale.d_date_sk
JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk AND inv.inv_date_sk = d_sale.d_date_sk
JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
JOIN date_dim d_return ON sr.sr_returned_date_sk = d_return.d_date_sk
WHERE d_sale.d_year = 2001
  AND i.i_units = 'Pound'
  AND p.p_discount_active = 'Y'
  AND ws.web_country = 'United States'
  AND ca.ca_state = 'CA'
  AND EXISTS (
        SELECT 1
        FROM promotion p2
        WHERE p2.p_item_sk = i.i_item_sk
          AND p2.p_discount_active = 'Y'
      )
ORDER BY ss.ss_ext_sales_price DESC
LIMIT 100
