WITH inv_agg AS (
    SELECT
        inv.inv_item_sk,
        inv.inv_date_sk,
        SUM(inv.inv_quantity_on_hand) AS total_qty_on_hand
    FROM inventory inv
    JOIN date_dim d_inv ON inv.inv_date_sk = d_inv.d_date_sk
    JOIN item i_inv ON inv.inv_item_sk = i_inv.i_item_sk
    GROUP BY inv.inv_item_sk, inv.inv_date_sk
),
sales_agg AS (
    SELECT
        d.d_year,
        i.i_item_id,
        i.i_brand,
        cp.cp_department,
        r.r_reason_desc,
        SUM(cs.cs_ext_sales_price) AS catalog_sales,
        SUM(ws.ws_ext_sales_price) AS web_sales,
        SUM(sr.sr_return_amt) AS store_returns_amount,
        SUM(cr.cr_return_amount) AS catalog_returns_amount,
        SUM(inv_agg.total_qty_on_hand) AS inventory_on_hand,
        SUM(cs.cs_net_profit) AS total_net_profit
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN customer_demographics cd_bill ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
    JOIN household_demographics hd_bill ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN customer_address ca_bill ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
    LEFT JOIN income_band ib ON hd_bill.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN catalog_returns cr ON cs.cs_order_number = cr.cr_order_number
    LEFT JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk AND ws.ws_item_sk = i.i_item_sk
    LEFT JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk AND sr.sr_returned_date_sk = d.d_date_sk
    RIGHT JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    LEFT JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
    LEFT JOIN inv_agg ON inv_agg.inv_item_sk = i.i_item_sk AND inv_agg.inv_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND i.i_current_price BETWEEN 10 AND 100
      AND cd_bill.cd_credit_rating = 'Good'
      AND sm.sm_type = 'AIR'
      AND cp.cp_department = 'Electronics'
    GROUP BY
        d.d_year,
        i.i_item_id,
        i.i_brand,
        cp.cp_department,
        r.r_reason_desc
)
SELECT
    d_year,
    i_item_id,
    i_brand,
    cp_department,
    r_reason_desc,
    catalog_sales,
    web_sales,
    store_returns_amount,
    catalog_returns_amount,
    inventory_on_hand,
    total_net_profit,
    ROW_NUMBER() OVER (ORDER BY catalog_sales DESC) AS sales_rank,
    CASE WHEN total_net_profit > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_status
FROM sales_agg
ORDER BY catalog_sales DESC
LIMIT 100
