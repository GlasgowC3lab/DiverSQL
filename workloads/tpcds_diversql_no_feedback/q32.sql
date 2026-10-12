WITH agg_inventory AS (
    SELECT
        inv_item_sk,
        inv_date_sk,
        SUM(inv_quantity_on_hand) AS total_qty
    FROM inventory
    GROUP BY inv_item_sk, inv_date_sk
)
SELECT
    d_sales.d_year,
    i.i_item_id,
    i.i_product_name,
    ss.ss_net_paid,
    ai.total_qty,
    p.p_promo_name,
    cc.cc_name,
    ca.ca_city,
    r.r_reason_desc,
    wr.wr_return_amt,
    wp.wp_url,
    ROW_NUMBER() OVER (PARTITION BY d_sales.d_year ORDER BY ss.ss_net_paid DESC) AS yearly_sales_rank
FROM agg_inventory ai
JOIN item i
    ON ai.inv_item_sk = i.i_item_sk
JOIN date_dim d_inv
    ON ai.inv_date_sk = d_inv.d_date_sk
JOIN store_sales ss
    ON ss.ss_item_sk = i.i_item_sk
JOIN date_dim d_sales
    ON ss.ss_sold_date_sk = d_sales.d_date_sk
JOIN time_dim t_sales
    ON ss.ss_sold_time_sk = t_sales.t_time_sk
JOIN promotion p
    ON ss.ss_promo_sk = p.p_promo_sk
JOIN call_center cc
    ON cc.cc_open_date_sk = d_sales.d_date_sk
JOIN customer_address ca
    ON ss.ss_addr_sk = ca.ca_address_sk
JOIN store_returns sr
    ON sr.sr_ticket_number = ss.ss_ticket_number
   AND sr.sr_item_sk = i.i_item_sk
JOIN reason r
    ON sr.sr_reason_sk = r.r_reason_sk
JOIN web_returns wr
    ON wr.wr_item_sk = i.i_item_sk
JOIN date_dim d_wr
    ON wr.wr_returned_date_sk = d_wr.d_date_sk
JOIN time_dim t_wr
    ON wr.wr_returned_time_sk = t_wr.t_time_sk
JOIN web_page wp
    ON wr.wr_web_page_sk = wp.wp_web_page_sk
WHERE d_sales.d_year = 2001
  AND i.i_current_price > 20
  AND p.p_discount_active = 'Y'
  AND t_sales.t_sub_shift = 'morning'
ORDER BY yearly_sales_rank ASC, d_sales.d_year DESC
LIMIT 100
