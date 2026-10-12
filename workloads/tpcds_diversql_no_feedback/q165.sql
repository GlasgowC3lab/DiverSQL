WITH sampled_ss AS (
    SELECT *
    FROM tpcds.store_sales
    TABLESAMPLE BERNOULLI (10)
),
joined AS (
    SELECT
        ss.ss_store_sk,
        s.s_store_id,
        s.s_store_name,
        s.s_state,
        d.d_year,
        i.i_brand,
        p.p_discount_active,
        inv.inv_quantity_on_hand,
        ss.ss_quantity,
        ss.ss_net_paid,
        ss.ss_net_profit,
        cc.cc_name
    FROM sampled_ss ss
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    JOIN inventory inv
        ON inv.inv_item_sk = i.i_item_sk
        AND inv.inv_date_sk = d.d_date_sk
    JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN catalog_sales cs
        ON cs.cs_item_sk = i.i_item_sk
        AND cs.cs_sold_date_sk = d.d_date_sk
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN web_sales ws
        ON ws.ws_sold_date_sk = d.d_date_sk
        AND ws.ws_item_sk = i.i_item_sk
    JOIN web_returns wr
        ON wr.wr_order_number = ws.ws_order_number
        AND wr.wr_item_sk = i.i_item_sk
        AND wr.wr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND s.s_state = 'CA'
      AND i.i_brand = 'Brand#23'
      AND p.p_discount_active = 'Y'
      AND inv.inv_quantity_on_hand > 500
      AND ss.ss_quantity BETWEEN 1 AND 10
      AND cc.cc_name LIKE '%Center%'
),
agg AS (
    SELECT
        s_store_id,
        s_store_name,
        d_year,
        SUM(ss_net_paid)   AS total_net_paid,
        SUM(ss_net_profit) AS total_net_profit
    FROM joined
    GROUP BY s_store_id, s_store_name, d_year
)
SELECT
    s_store_id,
    s_store_name,
    d_year,
    total_net_paid,
    total_net_profit,
    RANK() OVER (PARTITION BY d_year ORDER BY total_net_paid DESC)               AS sales_rank,
    ROW_NUMBER() OVER (PARTITION BY s_store_id ORDER BY total_net_paid DESC)   AS rn,
    CASE WHEN total_net_profit / NULLIF(total_net_paid, 0) > 0.2 THEN 'HIGH' ELSE 'LOW' END AS profit_margin_category
FROM agg
ORDER BY total_net_paid DESC
LIMIT 100
