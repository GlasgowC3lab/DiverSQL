WITH sales_raw AS (
    SELECT
        d.d_year AS year,
        d.d_moy AS month,
        i.i_category AS category,
        i.i_brand AS brand,
        s.s_state AS region,
        'Store' AS channel,
        cd.cd_gender AS gender,
        ss.ss_net_paid AS net_paid,
        ss.ss_net_profit AS net_profit,
        ss.ss_quantity AS quantity,
        ss.ss_ext_discount_amt AS discount_amt
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    LEFT JOIN store s ON ss.ss_store_sk = s.s_store_sk
    LEFT JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk

    UNION ALL

    SELECT
        d.d_year,
        d.d_moy,
        i.i_category,
        i.i_brand,
        cc.cc_state,
        'Catalog',
        cd.cd_gender,
        cs.cs_net_paid,
        cs.cs_net_profit,
        cs.cs_quantity,
        cs.cs_ext_discount_amt
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    LEFT JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    LEFT JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk

    UNION ALL

    SELECT
        d.d_year,
        d.d_moy,
        i.i_category,
        i.i_brand,
        wsite.web_state,
        'Web',
        cd.cd_gender,
        ws.ws_net_paid,
        ws.ws_net_profit,
        ws.ws_quantity,
        ws.ws_ext_discount_amt
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    LEFT JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
    LEFT JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
),

returns_raw AS (
    SELECT
        d.d_year AS year,
        d.d_moy AS month,
        i.i_category AS category,
        i.i_brand AS brand,
        s.s_state AS region,
        'Store' AS channel,
        cd.cd_gender AS gender,
        sr.sr_net_loss AS net_loss,
        sr.sr_return_quantity AS return_quantity
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    LEFT JOIN store s ON sr.sr_store_sk = s.s_store_sk
    LEFT JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk

    UNION ALL

    SELECT
        d.d_year,
        d.d_moy,
        i.i_category,
        i.i_brand,
        cc.cc_state,
        'Catalog',
        cd.cd_gender,
        cr.cr_net_loss,
        cr.cr_return_quantity
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    LEFT JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    LEFT JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk

    UNION ALL

    SELECT
        d.d_year,
        d.d_moy,
        i.i_category,
        i.i_brand,
        NULL AS region,
        'Web' AS channel,
        cd.cd_gender,
        wr.wr_net_loss,
        wr.wr_return_quantity
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    LEFT JOIN customer_demographics cd ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
),

agg AS (
    SELECT
        s.year,
        s.month,
        s.category,
        s.brand,
        s.region,
        s.channel,
        s.gender,
        SUM(s.net_paid) AS total_net_paid,
        SUM(s.net_profit) AS total_net_profit,
        SUM(s.quantity) AS total_quantity,
        SUM(s.discount_amt) AS total_discount,
        COALESCE(SUM(r.net_loss), 0) AS total_return_loss,
        COALESCE(SUM(r.return_quantity), 0) AS total_return_quantity
    FROM sales_raw s
    LEFT JOIN returns_raw r
        ON s.year = r.year
       AND s.month = r.month
       AND s.category = r.category
       AND s.brand = r.brand
       AND (s.region = r.region OR (s.region IS NULL AND r.region IS NULL))
       AND s.channel = r.channel
       AND s.gender = r.gender
    WHERE s.year BETWEEN 2000 AND 2002
    GROUP BY s.year, s.month, s.category, s.brand, s.region, s.channel, s.gender
)

SELECT
    year,
    month,
    category,
    brand,
    region,
    channel,
    gender,
    total_net_paid,
    total_net_profit,
    total_quantity,
    total_discount,
    total_return_loss,
    total_return_quantity,
    CASE WHEN total_net_paid <> 0 THEN ROUND(100.0 * total_return_loss / total_net_paid, 2) END AS return_loss_pct,
    ROUND(total_discount / NULLIF(total_quantity, 0), 2) AS avg_discount_per_unit,
    RANK() OVER (PARTITION BY year, month ORDER BY total_net_paid DESC) AS revenue_rank
FROM agg
ORDER BY year, month, total_net_paid DESC
LIMIT 200
