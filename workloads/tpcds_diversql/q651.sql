WITH base AS (
    SELECT
        d.d_year,
        d.d_date,
        i.i_category,
        i.i_item_id,
        s.s_store_sk,
        s.s_store_id,
        s.s_state,
        p.p_promo_name,
        p.p_channel_email,
        cs.cs_ext_sales_price,
        sr.sr_return_amt,
        ws.ws_ext_sales_price,
        wr.wr_return_amt,
        cc.cc_gmt_offset,
        t.t_meal_time,
        cu.c_customer_sk
    FROM tpcds.date_dim d
    LEFT JOIN tpcds.call_center cc
        ON cc.cc_closed_date_sk = d.d_date_sk
    LEFT JOIN tpcds.catalog_sales cs
        ON cs.cs_sold_date_sk = d.d_date_sk
    LEFT JOIN tpcds.customer cu
        ON cs.cs_bill_customer_sk = cu.c_customer_sk
    LEFT JOIN tpcds.time_dim t
        ON cs.cs_sold_time_sk = t.t_time_sk
    LEFT JOIN tpcds.item i
        ON cs.cs_item_sk = i.i_item_sk
    LEFT JOIN tpcds.promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    LEFT JOIN tpcds.store s
        ON s.s_closed_date_sk = d.d_date_sk
    LEFT JOIN tpcds.store_returns sr
        ON sr.sr_store_sk = s.s_store_sk
        AND sr.sr_item_sk = i.i_item_sk
        AND sr.sr_customer_sk = cu.c_customer_sk
        AND sr.sr_returned_date_sk = d.d_date_sk
        AND sr.sr_return_time_sk = t.t_time_sk
    LEFT JOIN tpcds.web_sales ws
        ON ws.ws_item_sk = i.i_item_sk
        AND ws.ws_sold_date_sk = d.d_date_sk
        AND ws.ws_sold_time_sk = t.t_time_sk
    LEFT JOIN tpcds.web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN tpcds.web_returns wr
        ON wr.wr_order_number = ws.ws_order_number
        AND wr.wr_item_sk = i.i_item_sk
        AND wr.wr_returned_date_sk = d.d_date_sk
        AND wr.wr_returned_time_sk = t.t_time_sk
        AND wr.wr_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN tpcds.inventory inv
        ON inv.inv_item_sk = i.i_item_sk
        AND inv.inv_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND t.t_meal_time = 'lunch'
      AND s.s_state = 'CA'
      AND p.p_channel_email = 'Y'
      AND i.i_category = 'Sports'
      AND cc.cc_gmt_offset > -5
),
agg AS (
    SELECT
        s_store_sk,
        i_category,
        SUM(cs_ext_sales_price) AS total_catalog_sales,
        SUM(ws_ext_sales_price) AS total_web_sales,
        SUM(sr_return_amt) AS total_store_returns,
        SUM(wr_return_amt) AS total_web_returns
    FROM base
    GROUP BY s_store_sk, i_category
),
filtered AS (
    SELECT
        s_store_sk,
        i_category,
        total_catalog_sales,
        total_web_sales,
        total_store_returns,
        total_web_returns,
        (total_catalog_sales + total_web_sales - total_store_returns - total_web_returns) AS net_sales
    FROM agg
    WHERE (total_catalog_sales + total_web_sales) > 20000
),
high_sales_stores AS (
    SELECT s_store_sk FROM agg WHERE total_catalog_sales > 50000
),
diff_stores AS (
    SELECT s_store_sk FROM agg WHERE total_catalog_sales > 30000
    EXCEPT
    SELECT s_store_sk FROM agg WHERE total_store_returns > 2000
)
SELECT
    f.s_store_sk,
    f.i_category,
    f.net_sales,
    (
        SELECT COUNT(DISTINCT sr_inner.sr_item_sk)
        FROM tpcds.store_returns sr_inner
        WHERE sr_inner.sr_store_sk = f.s_store_sk
    ) AS distinct_items_returned,
    CASE
        WHEN f.s_store_sk IN (SELECT s_store_sk FROM high_sales_stores) THEN 'High'
        ELSE 'Low'
    END AS sales_tier
FROM (
    SELECT * FROM filtered WHERE MOD(s_store_sk, 2) = 0
    UNION DISTINCT
    SELECT * FROM filtered WHERE MOD(s_store_sk, 2) = 1
) AS f
WHERE f.net_sales > (
        SELECT AVG(net_sales) FROM filtered
    )
  AND f.s_store_sk NOT IN (SELECT s_store_sk FROM diff_stores)
ORDER BY f.net_sales DESC
OFFSET 0 FETCH FIRST 100 ROWS ONLY
