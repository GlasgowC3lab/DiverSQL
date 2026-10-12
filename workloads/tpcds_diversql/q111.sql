WITH unified AS (
    SELECT
        i.i_category,
        d.d_year,
        cs.cs_net_paid,
        cr.cr_net_loss,
        sr.sr_net_loss,
        inv.inv_quantity_on_hand,
        cust.c_customer_sk
    FROM catalog_sales cs
    JOIN catalog_returns cr
      ON cr.cr_order_number = cs.cs_order_number
     AND cr.cr_item_sk = cs.cs_item_sk
    JOIN store_returns sr
      ON sr.sr_item_sk = cs.cs_item_sk
    JOIN item i
      ON cs.cs_item_sk = i.i_item_sk
    JOIN date_dim d
      ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN warehouse w
      ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN customer cust
      ON cs.cs_bill_customer_sk = cust.c_customer_sk
    JOIN household_demographics hd
      ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca
      ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN reason r
      ON cr.cr_reason_sk = r.r_reason_sk
    JOIN promotion p
      ON cs.cs_promo_sk = p.p_promo_sk
    JOIN inventory inv
      ON inv.inv_item_sk = i.i_item_sk
     AND inv.inv_warehouse_sk = w.w_warehouse_sk
     AND inv.inv_date_sk = d.d_date_sk
    JOIN web_site ws
      ON ws.web_open_date_sk = d.d_date_sk
    WHERE w.w_country = 'United States'
      AND hd.hd_buy_potential = '>10000'
      AND ca.ca_city = 'Jackson'
      AND hd.hd_vehicle_count >= 0
    UNION
    SELECT
        i.i_category,
        d.d_year,
        cs.cs_net_paid,
        cr.cr_net_loss,
        sr.sr_net_loss,
        inv.inv_quantity_on_hand,
        cust.c_customer_sk
    FROM catalog_sales cs
    JOIN catalog_returns cr
      ON cr.cr_order_number = cs.cs_order_number
     AND cr.cr_item_sk = cs.cs_item_sk
    JOIN store_returns sr
      ON sr.sr_item_sk = cs.cs_item_sk
    JOIN item i
      ON cs.cs_item_sk = i.i_item_sk
    JOIN date_dim d
      ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN warehouse w
      ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN customer cust
      ON cs.cs_bill_customer_sk = cust.c_customer_sk
    JOIN household_demographics hd
      ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca
      ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN reason r
      ON cr.cr_reason_sk = r.r_reason_sk
    JOIN promotion p
      ON cs.cs_promo_sk = p.p_promo_sk
    JOIN inventory inv
      ON inv.inv_item_sk = i.i_item_sk
     AND inv.inv_warehouse_sk = w.w_warehouse_sk
     AND inv.inv_date_sk = d.d_date_sk
    JOIN web_site ws
      ON ws.web_open_date_sk = d.d_date_sk
    WHERE ws.web_state = 'CA'
      AND d.d_date BETWEEN DATE '2002-01-01' AND DATE '2002-12-31'
      AND w.w_warehouse_sq_ft > 500000
      AND ca.ca_street_name = 'Jackson'
)
SELECT
    i_category,
    d_year,
    SUM(cs_net_paid) AS total_sales,
    SUM(cr_net_loss) AS total_return_loss,
    SUM(sr_net_loss) AS total_store_return_loss,
    SUM(inv_quantity_on_hand) AS total_inventory,
    COUNT(DISTINCT c_customer_sk) AS distinct_customers
FROM unified
GROUP BY i_category, d_year
ORDER BY total_sales DESC
LIMIT 100
