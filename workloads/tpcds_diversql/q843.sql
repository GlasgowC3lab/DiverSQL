WITH intersect_items AS (
    SELECT cs_item_sk AS item_sk
    FROM tpcds.catalog_sales
    WHERE cs_quantity > 10
    INTERSECT
    SELECT inv_item_sk
    FROM tpcds.inventory
    WHERE inv_quantity_on_hand > 500
),
base AS (
    SELECT
        dd.d_year,
        cc.cc_name,
        cp.cp_department,
        p.p_promo_name,
        c.c_birth_country,
        td.t_meal_time,
        wp.wp_type,
        cs.cs_ext_sales_price,
        cs.cs_net_profit,
        sr.sr_return_amt,
        wr.wr_return_amt,
        inv.inv_quantity_on_hand,
        cs.cs_item_sk
    FROM tpcds.date_dim dd
    JOIN tpcds.call_center cc ON cc.cc_closed_date_sk = dd.d_date_sk
    JOIN tpcds.catalog_sales cs ON cs.cs_call_center_sk = cc.cc_call_center_sk
                                 AND cs.cs_sold_date_sk = dd.d_date_sk
    JOIN tpcds.catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN tpcds.promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN tpcds.inventory inv ON inv.inv_date_sk = dd.d_date_sk
    JOIN tpcds.store_returns sr ON sr.sr_returned_date_sk = dd.d_date_sk
    JOIN tpcds.time_dim td ON sr.sr_return_time_sk = td.t_time_sk
    JOIN tpcds.customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN tpcds.customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN tpcds.web_page wp ON wp.wp_customer_sk = c.c_customer_sk
    JOIN tpcds.web_returns wr ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE dd.d_year = 2001
      AND c.c_birth_country = 'SWITZERLAND'
      AND td.t_meal_time = 'dinner'
      AND wp.wp_autogen_flag = 'N'
      AND EXISTS (
          SELECT 1 FROM tpcds.store_returns sr2
          WHERE sr2.sr_customer_sk = c.c_customer_sk
            AND sr2.sr_returned_date_sk = dd.d_date_sk
      )
      AND cs.cs_ext_sales_price > (
          SELECT AVG(cs2.cs_ext_sales_price)
          FROM tpcds.catalog_sales cs2
      )
      AND cs.cs_item_sk IN (SELECT item_sk FROM intersect_items)
)
SELECT
    d_year,
    cc_name,
    cp_department,
    p_promo_name,
    c_birth_country,
    t_meal_time,
    wp_type,
    SUM(cs_ext_sales_price) AS total_sales,
    AVG(cs_net_profit) AS avg_profit,
    SUM(sr_return_amt) AS total_store_return,
    SUM(wr_return_amt) AS total_web_return,
    COUNT(*) AS txn_count,
    ROW_NUMBER() OVER (ORDER BY SUM(cs_ext_sales_price) DESC) AS row_num
FROM base
GROUP BY
    d_year,
    cc_name,
    cp_department,
    p_promo_name,
    c_birth_country,
    t_meal_time,
    wp_type
ORDER BY total_sales DESC
LIMIT 100
