WITH sampled_sales AS (
    SELECT *
    FROM tpcds.web_sales
    TABLESAMPLE BERNOULLI (10)
),
joined_data AS (
    SELECT
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_sold_date_sk,
        ws.ws_quantity,
        ws.ws_ext_sales_price,
        ws.ws_net_profit,
        i.i_item_id,
        i.i_product_name,
        d.d_year,
        d.d_month_seq,
        t.t_hour,
        p.p_promo_name,
        p.p_discount_active,
        r.r_reason_desc,
        s.s_store_id,
        s.s_state,
        cc.cc_name,
        cc.cc_class,
        inv.inv_quantity_on_hand
    FROM sampled_sales ws
    JOIN tpcds.date_dim d
        ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN tpcds.time_dim t
        ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN tpcds.item i
        ON ws.ws_item_sk = i.i_item_sk
    LEFT JOIN tpcds.promotion p
        ON ws.ws_promo_sk = p.p_promo_sk
    LEFT JOIN tpcds.inventory inv
        ON inv.inv_date_sk = d.d_date_sk
        AND inv.inv_item_sk = i.i_item_sk
    LEFT JOIN tpcds.store s
        ON s.s_closed_date_sk = d.d_date_sk
    FULL OUTER JOIN tpcds.call_center cc
        ON cc.cc_closed_date_sk = d.d_date_sk
    LEFT JOIN tpcds.web_returns wr
        ON wr.wr_order_number = ws.ws_order_number
        AND wr.wr_item_sk = ws.ws_item_sk
        AND wr.wr_returned_date_sk = d.d_date_sk
    LEFT JOIN tpcds.reason r
        ON wr.wr_reason_sk = r.r_reason_sk
    WHERE d.d_year = 2001
      AND t.t_hour BETWEEN 9 AND 17
      AND s.s_state = 'CA'
      AND cc.cc_class = 'large'
      AND p.p_discount_active = 'Y'
      AND i.i_brand = 'Brand#12'
)
SELECT
    jd.ws_order_number,
    jd.i_item_id,
    jd.i_product_name,
    jd.d_year,
    jd.t_hour,
    jd.ws_quantity,
    jd.ws_ext_sales_price,
    jd.ws_net_profit,
    jd.s_store_id,
    jd.cc_name,
    jd.inv_quantity_on_hand,
    jd.r_reason_desc,
    ROW_NUMBER() OVER (PARTITION BY jd.i_item_id ORDER BY jd.ws_ext_sales_price DESC) AS sales_rank,
    AVG(jd.ws_ext_sales_price) OVER (PARTITION BY jd.d_year ORDER BY jd.ws_ext_sales_price ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS moving_avg_price,
    CASE WHEN jd.ws_net_profit > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_flag
FROM joined_data jd
CROSS JOIN LATERAL (
    SELECT DISTINCT r2.r_reason_desc
    FROM tpcds.reason r2
    WHERE r2.r_reason_desc = jd.r_reason_desc
) AS dr
WHERE dr.r_reason_desc IS NOT NULL
ORDER BY jd.d_year DESC, jd.ws_ext_sales_price DESC
LIMIT 100
