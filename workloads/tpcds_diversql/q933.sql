WITH cs_sample AS (
    SELECT *
    FROM catalog_sales
    TABLESAMPLE BERNOULLI (10)
),
excluded_orders AS (
    SELECT cs_order_number
    FROM cs_sample
    EXCEPT
    SELECT ws_order_number
    FROM web_sales
),
joined_data AS (
    SELECT
        cs.cs_order_number,
        cs.cs_quantity,
        cs.cs_ext_sales_price,
        cs.cs_net_profit,
        cp.cp_department,
        p.p_promo_name,
        d.d_year,
        w.w_warehouse_name,
        ss.ss_net_profit      AS store_net_profit,
        ws.ws_net_profit      AS web_net_profit,
        ws.ws_quantity,
        ws.ws_sales_price,
        wr.wr_net_loss,
        r.r_reason_desc,
        la.adj_ws_sales,
        p.p_discount_active,
        we.web_country
    FROM cs_sample cs
    JOIN excluded_orders eo ON cs.cs_order_number = eo.cs_order_number
    JOIN catalog_page cp           ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN promotion p               ON cs.cs_promo_sk = p.p_promo_sk
    JOIN date_dim d                ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN warehouse w               ON cs.cs_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN store_sales ss      ON ss.ss_sold_date_sk = d.d_date_sk
                                 AND ss.ss_promo_sk = p.p_promo_sk
    LEFT JOIN web_sales ws        ON ws.ws_sold_date_sk = d.d_date_sk
                                 AND ws.ws_promo_sk = p.p_promo_sk
    LEFT JOIN LATERAL (
        SELECT CASE WHEN ws.ws_quantity > 20
                    THEN ws.ws_quantity * ws.ws_sales_price
                    ELSE ws.ws_sales_price
               END AS adj_ws_sales
    ) la ON TRUE
    LEFT JOIN web_returns wr      ON wr.wr_returned_date_sk = d.d_date_sk
                                 AND wr.wr_order_number = ws.ws_order_number
    LEFT JOIN reason r            ON wr.wr_reason_sk = r.r_reason_sk
    LEFT JOIN web_site we          ON ws.ws_web_site_sk = we.web_site_sk
    LEFT JOIN date_dim d_open      ON we.web_open_date_sk = d_open.d_date_sk
    LEFT JOIN date_dim d_close     ON we.web_close_date_sk = d_close.d_date_sk
    LEFT JOIN promotion p_ws       ON ws.ws_promo_sk = p_ws.p_promo_sk
    LEFT JOIN promotion p_ss       ON ss.ss_promo_sk = p_ss.p_promo_sk
    LEFT JOIN warehouse w_ws       ON ws.ws_warehouse_sk = w_ws.w_warehouse_sk
)
SELECT *
FROM (
    SELECT
        p_promo_name,
        d_year,
        COUNT(DISTINCT cs_order_number)                     AS catalog_order_cnt,
        SUM(cs_ext_sales_price)                            AS total_catalog_sales,
        SUM(CASE WHEN cs_quantity > 5 THEN cs_ext_sales_price ELSE 0 END) AS high_qty_catalog_sales,
        SUM(store_net_profit)                              AS total_store_profit,
        SUM(web_net_profit)                                AS total_web_profit,
        SUM(wr_net_loss)                                   AS total_return_loss,
        COUNT(DISTINCT r_reason_desc)                      AS distinct_return_reasons,
        SUM(adj_ws_sales)                                  AS total_adjusted_web_sales,
        ROW_NUMBER() OVER (
            PARTITION BY p_promo_name
            ORDER BY (SUM(cs_ext_sales_price) + SUM(store_net_profit) + SUM(web_net_profit)) DESC
        )                                                  AS promo_rank
    FROM joined_data
    WHERE
        d_year = 2001
        AND p_discount_active = 'Y'
        AND cp_department = 'Home'
        AND web_country = 'United States'
    GROUP BY
        p_promo_name,
        d_year
    HAVING
        COUNT(DISTINCT cs_order_number) > 10
) t
WHERE promo_rank <= 5
ORDER BY promo_rank, total_catalog_sales DESC
LIMIT 100
