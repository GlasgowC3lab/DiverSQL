WITH
    /* Sample 10% of catalog_sales to limit data volume */
    sampled_cs AS (
        SELECT *
        FROM catalog_sales
        TABLESAMPLE BERNOULLI (10)
    ),

    /* Lateral sub‑query that computes the total discount for each order */
    cs_with_lateral AS (
        SELECT
            cs.*, 
            d.total_discount
        FROM sampled_cs cs
        CROSS JOIN LATERAL (
            SELECT SUM(cs2.cs_ext_discount_amt) AS total_discount
            FROM catalog_sales cs2
            WHERE cs2.cs_order_number = cs.cs_order_number
        ) d
    ),

    /* First branch – uses catalog_sales and related dimensions */
    branch_a AS (
        SELECT
            cs.cs_order_number                         AS order_id,
            cs.cs_sold_date_sk                         AS sold_date_sk,
            cs.cs_quantity                             AS quantity,
            cs.cs_net_paid                             AS net_paid,
            cc.cc_state                                AS state,
            c.c_customer_id                            AS customer_id,
            cd.cd_gender                               AS gender,
            hd.hd_buy_potential                        AS buy_potential,
            ib.ib_lower_bound                          AS income_lower,
            CAST(NULL AS VARCHAR)                      AS reason_desc,
            'catalog'                                  AS source,
            td.t_hour                                  AS hour
        FROM cs_with_lateral cs
        JOIN call_center cc
            ON cs.cs_call_center_sk = cc.cc_call_center_sk
        JOIN warehouse w
            ON cs.cs_warehouse_sk = w.w_warehouse_sk
        JOIN customer c
            ON cs.cs_bill_customer_sk = c.c_customer_sk
        JOIN customer_demographics cd
            ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
        JOIN household_demographics hd
            ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
        JOIN income_band ib
            ON hd.hd_income_band_sk = ib.ib_income_band_sk
        JOIN item i
            ON cs.cs_item_sk = i.i_item_sk
        JOIN time_dim td
            ON cs.cs_sold_time_sk = td.t_time_sk
        WHERE cc.cc_state = 'CA'
          AND cs.cs_quantity BETWEEN 1 AND 5
          AND cs.cs_net_paid > 100
          AND cd.cd_gender = 'M'
          AND ib.ib_upper_bound < 50000
          AND i.i_color = 'red'
    ),

    /* Second branch – combines store and web channels with a FULL OUTER JOIN */
    branch_b AS (
        SELECT
            /* create a synthetic order identifier */
            COALESCE(ss.ss_ticket_number, i.i_item_sk) * 1000 + COALESCE(ws.ws_order_number, 0) AS order_id,
            ss.ss_sold_date_sk                                                       AS sold_date_sk,
            COALESCE(ss.ss_quantity, ws.ws_quantity)                                 AS quantity,
            COALESCE(ss.ss_net_paid, ws.ws_net_paid)                                 AS net_paid,
            CAST(NULL AS VARCHAR)                                                    AS state,
            c.c_customer_id                                                          AS customer_id,
            cd.cd_gender                                                             AS gender,
            hd.hd_buy_potential                                                      AS buy_potential,
            ib.ib_lower_bound                                                        AS income_lower,
            r.r_reason_desc                                                         AS reason_desc,
            'store_web'                                                              AS source,
            td.t_hour                                                                AS hour
        FROM store_sales ss
        FULL OUTER JOIN item i
            ON ss.ss_item_sk = i.i_item_sk
        LEFT JOIN store_returns sr
            ON ss.ss_ticket_number = sr.sr_ticket_number
        LEFT JOIN reason r
            ON sr.sr_reason_sk = r.r_reason_sk
        LEFT JOIN customer c
            ON ss.ss_customer_sk = c.c_customer_sk
        LEFT JOIN customer_demographics cd
            ON ss.ss_cdemo_sk = cd.cd_demo_sk
        LEFT JOIN household_demographics hd
            ON ss.ss_hdemo_sk = hd.hd_demo_sk
        LEFT JOIN income_band ib
            ON hd.hd_income_band_sk = ib.ib_income_band_sk
        LEFT JOIN time_dim td
            ON ss.ss_sold_time_sk = td.t_time_sk
        /* bring in the web channel – joins through the shared item */
        LEFT JOIN web_sales ws
            ON i.i_item_sk = ws.ws_item_sk
        LEFT JOIN web_returns wr
            ON ws.ws_order_number = wr.wr_order_number
        WHERE (ss.ss_quantity > 2 OR ws.ws_quantity > 1)
          AND (r.r_reason_desc LIKE '%work%' OR r.r_reason_desc IS NULL)
          AND td.t_hour BETWEEN 9 AND 17
          AND i.i_color IN ('blue', 'red')
          AND ib.ib_lower_bound >= 20000
    ),

    /* Union the two branches – distinct rows only */
    unified AS (
        SELECT * FROM branch_a
        UNION DISTINCT
        SELECT * FROM branch_b
    )
SELECT
    state,
    gender,
    buy_potential,
    income_lower,
    reason_desc,
    hour,
    source,
    COUNT(*)                                     AS orders_cnt,
    SUM(net_paid)                                AS total_net_paid,
    AVG(quantity)                                AS avg_quantity,
    MIN(net_paid)                                AS min_net_paid,
    MAX(net_paid)                                AS max_net_paid,
    /* Running total of net_paid per state, ordered by source */
    SUM(SUM(net_paid)) OVER (PARTITION BY state ORDER BY source ROWS UNBOUNDED PRECEDING) AS running_total_by_state
FROM unified
GROUP BY
    state,
    gender,
    buy_potential,
    income_lower,
    reason_desc,
    hour,
    source
ORDER BY total_net_paid DESC
OFFSET 0 FETCH NEXT 100 ROWS ONLY
