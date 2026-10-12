WITH sampled_inventory AS (
   SELECT *
   FROM inventory TABLESAMPLE BERNOULLI (10)
   WHERE inv_quantity_on_hand > 0
),
web_data AS (
   SELECT
        ws.ws_order_number               AS order_number,
        ws.ws_sold_date_sk               AS date_sk,
        d.d_year,
        i.i_brand_id,
        i.i_manufact,
        c.c_customer_id,
        cd.cd_gender,
        ca.ca_state,
        ws.ws_ext_sales_price            AS sales_price,
        ws.ws_net_profit                 AS profit,
        wr.wr_return_amt,
        wr.wr_net_loss,
        r.r_reason_desc,
        td.t_hour,
        td.t_sub_shift,
        inv.inv_quantity_on_hand
   FROM web_sales ws
   JOIN date_dim d               ON ws.ws_sold_date_sk = d.d_date_sk
   JOIN time_dim td              ON ws.ws_sold_time_sk = td.t_time_sk
   JOIN item i                   ON ws.ws_item_sk = i.i_item_sk
   JOIN customer c               ON ws.ws_bill_customer_sk = c.c_customer_sk
   JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
   JOIN customer_address ca      ON ws.ws_bill_addr_sk = ca.ca_address_sk
   JOIN web_page wp              ON ws.ws_web_page_sk = wp.wp_web_page_sk
   LEFT JOIN web_returns wr      ON wr.wr_order_number = ws.ws_order_number
                                 AND wr.wr_item_sk = ws.ws_item_sk
   LEFT JOIN reason r            ON wr.wr_reason_sk = r.r_reason_sk
   LEFT JOIN sampled_inventory inv ON inv.inv_item_sk = i.i_item_sk
                                 AND inv.inv_date_sk = d.d_date_sk
   WHERE d.d_year BETWEEN 2000 AND 2002
     AND i.i_brand_id IN (6008007, 3002001)
     AND cd.cd_gender = 'M'
     AND ca.ca_state = 'CA'
     AND (r.r_reason_desc IS NOT NULL OR wr.wr_return_amt IS NULL)
),
store_data AS (
   SELECT
        ss.ss_ticket_number            AS order_number,
        ss.ss_sold_date_sk              AS date_sk,
        d.d_year,
        i.i_brand_id,
        i.i_manufact,
        c.c_customer_id,
        cd.cd_gender,
        ca.ca_state,
        ss.ss_ext_sales_price          AS sales_price,
        ss.ss_net_profit               AS profit,
        CAST(NULL AS decimal(7,2))     AS wr_return_amt,
        CAST(NULL AS decimal(7,2))     AS wr_net_loss,
        CAST(NULL AS varchar)          AS r_reason_desc,
        td.t_hour,
        td.t_sub_shift,
        inv.inv_quantity_on_hand
   FROM store_sales ss
   JOIN date_dim d               ON ss.ss_sold_date_sk = d.d_date_sk
   JOIN time_dim td              ON ss.ss_sold_time_sk = td.t_time_sk
   JOIN item i                   ON ss.ss_item_sk = i.i_item_sk
   JOIN customer c               ON ss.ss_customer_sk = c.c_customer_sk
   JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
   JOIN customer_address ca      ON ss.ss_addr_sk = ca.ca_address_sk
   LEFT JOIN sampled_inventory inv ON inv.inv_item_sk = i.i_item_sk
                                 AND inv.inv_date_sk = d.d_date_sk
   WHERE d.d_year BETWEEN 2000 AND 2002
     AND i.i_brand_id IN (6008007, 3002001)
     AND cd.cd_gender = 'M'
     AND ca.ca_state = 'CA'
),
combined AS (
   SELECT * FROM web_data
   UNION ALL
   SELECT * FROM store_data
),
aggregated AS (
   SELECT
        d_year,
        i_brand_id,
        cd_gender,
        SUM(sales_price)                AS total_sales,
        SUM(profit)                     AS total_profit,
        SUM(COALESCE(wr_return_amt,0))  AS total_returns,
        SUM(COALESCE(wr_net_loss,0))    AS total_return_loss,
        COUNT(DISTINCT order_number)    AS orders,
        AVG(inv_quantity_on_hand)       AS avg_inventory_qty
   FROM combined
   GROUP BY d_year, i_brand_id, cd_gender
),
final AS (
   SELECT
        d_year,
        i_brand_id,
        cd_gender,
        total_sales,
        total_profit,
        total_returns,
        total_return_loss,
        orders,
        avg_inventory_qty,
        ROW_NUMBER() OVER (ORDER BY total_sales DESC) AS sales_rank
   FROM aggregated
   WHERE total_sales > 10000
     AND total_profit > 0
     AND orders >= 10
     AND avg_inventory_qty IS NOT NULL
     AND total_returns < total_sales
)
SELECT *
FROM final
CROSS JOIN (VALUES (2000), (2001), (2002)) AS yr(year)
WHERE yr.year = final.d_year
ORDER BY sales_rank
LIMIT 100
