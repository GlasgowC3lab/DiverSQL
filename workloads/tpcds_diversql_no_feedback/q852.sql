WITH intersect_keys AS (
    SELECT ss_store_sk FROM store_sales WHERE ss_quantity > 2
    INTERSECT
    SELECT ss_store_sk FROM store_sales WHERE ss_sales_price > 200
),
joined_data AS (
    SELECT 
        ss.ss_sold_date_sk,
        ss.ss_sold_time_sk,
        ss.ss_item_sk,
        ss.ss_customer_sk,
        ss.ss_cdemo_sk,
        ss.ss_store_sk,
        ss.ss_promo_sk,
        ss.ss_quantity,
        ss.ss_sales_price,
        ss.ss_ext_sales_price,
        d.d_year,
        t.t_hour,
        i.i_category,
        i.i_current_price,
        c.c_preferred_cust_flag,
        cd.cd_gender,
        s.s_state,
        p.p_promo_name,
        inv.inv_quantity_on_hand,
        w.w_state AS warehouse_state,
        cc.cc_name,
        ws.web_name
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN inventory inv ON inv.inv_date_sk = d.d_date_sk AND inv.inv_item_sk = i.i_item_sk
    JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
    JOIN call_center cc ON cc.cc_open_date_sk = d.d_date_sk
    JOIN web_site ws ON ws.web_open_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND t.t_hour BETWEEN 9 AND 17
      AND i.i_current_price > 50
      AND cd.cd_gender = 'M'
      AND s.s_state = 'CA'
      AND EXISTS (
          SELECT 1 FROM promotion p2
          WHERE p2.p_promo_sk = ss.ss_promo_sk
            AND p2.p_channel_email = 'Y'
      )
)
SELECT 
    jd.d_year,
    jd.s_state,
    jd.i_category,
    COUNT(*) AS transaction_cnt,
    SUM(jd.ss_ext_sales_price) AS total_sales,
    AVG(jd.ss_sales_price) AS avg_unit_price,
    MIN(jd.ss_ext_sales_price) AS min_sale,
    MAX(jd.ss_ext_sales_price) AS max_sale
FROM joined_data jd
JOIN intersect_keys ik ON jd.ss_store_sk = ik.ss_store_sk
GROUP BY jd.d_year, jd.s_state, jd.i_category
ORDER BY total_sales DESC
LIMIT 100
