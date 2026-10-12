WITH sales AS (
    SELECT
        d.d_year AS year,
        d.d_moy AS month,
        c.cc_state AS state,
        cd.cd_gender AS gender,
        cd.cd_marital_status AS marital_status,
        'catalog' AS channel,
        cs.cs_item_sk AS item_sk,
        cs.cs_quantity AS quantity,
        cs.cs_net_paid_inc_tax AS net_paid,
        cs.cs_net_profit AS profit
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN call_center c ON cs.cs_call_center_sk = c.cc_call_center_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    WHERE d.d_year = 1998
    UNION ALL
    SELECT
        d.d_year AS year,
        d.d_moy AS month,
        s.s_state AS state,
        cd.cd_gender AS gender,
        cd.cd_marital_status AS marital_status,
        'store' AS channel,
        ss.ss_item_sk AS item_sk,
        ss.ss_quantity AS quantity,
        ss.ss_net_paid_inc_tax AS net_paid,
        ss.ss_net_profit AS profit
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    WHERE d.d_year = 1998
    UNION ALL
    SELECT
        d.d_year AS year,
        d.d_moy AS month,
        w.web_state AS state,
        cd.cd_gender AS gender,
        cd.cd_marital_status AS marital_status,
        'web' AS channel,
        ws.ws_item_sk AS item_sk,
        ws.ws_quantity AS quantity,
        ws.ws_net_paid_inc_tax AS net_paid,
        ws.ws_net_profit AS profit
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    WHERE d.d_year = 1998
), item_agg AS (
    SELECT
        year,
        month,
        channel,
        state,
        gender,
        marital_status,
        sum(profit) AS total_profit,
        sum(net_paid) AS total_paid,
        sum(quantity) AS total_quantity,
        count(DISTINCT item_sk) AS distinct_items
    FROM sales
    GROUP BY year, month, channel, state, gender, marital_status
), top_items AS (
    SELECT
        year,
        month,
        channel,
        state,
        gender,
        marital_status,
        item_sk,
        sum(profit) AS item_profit,
        row_number() OVER (PARTITION BY year, month, channel, state, gender, marital_status ORDER BY sum(profit) DESC) AS rn
    FROM sales
    GROUP BY year, month, channel, state, gender, marital_status, item_sk
    HAVING sum(profit) > 0
)
SELECT
    ia.year,
    ia.month,
    ia.channel,
    ia.state,
    ia.gender,
    ia.marital_status,
    ia.total_profit,
    ia.total_paid,
    ia.total_quantity,
    ia.distinct_items,
    ti.item_sk,
    ti.item_profit
FROM item_agg ia
LEFT JOIN top_items ti
    ON ia.year = ti.year
   AND ia.month = ti.month
   AND ia.channel = ti.channel
   AND ia.state = ti.state
   AND ia.gender = ti.gender
   AND ia.marital_status = ti.marital_status
   AND ti.rn <= 3
ORDER BY ia.year, ia.month, ia.channel, ia.total_profit DESC
LIMIT 200
