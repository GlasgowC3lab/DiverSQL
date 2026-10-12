WITH
sales_unified AS (
    SELECT
        'catalog' AS channel,
        cs.cs_order_number AS order_number,
        cs.cs_item_sk AS item_sk,
        cs.cs_sold_date_sk AS date_sk,
        COALESCE(cs.cs_net_paid, 0) AS net_paid,
        COALESCE(cs.cs_net_profit, 0) AS net_profit,
        COALESCE(cs.cs_ext_sales_price, 0) AS ext_sales_price,
        cs.cs_quantity AS quantity,
        cs.cs_call_center_sk AS cc_sk,
        CAST(NULL AS integer) AS store_sk,
        CAST(NULL AS integer) AS web_site_sk
    FROM catalog_sales cs
    UNION ALL
    SELECT
        'store' AS channel,
        ss.ss_ticket_number AS order_number,
        ss.ss_item_sk AS item_sk,
        ss.ss_sold_date_sk AS date_sk,
        COALESCE(ss.ss_net_paid, 0) AS net_paid,
        COALESCE(ss.ss_net_profit, 0) AS net_profit,
        COALESCE(ss.ss_ext_sales_price, 0) AS ext_sales_price,
        ss.ss_quantity AS quantity,
        CAST(NULL AS integer) AS cc_sk,
        ss.ss_store_sk AS store_sk,
        CAST(NULL AS integer) AS web_site_sk
    FROM store_sales ss
    UNION ALL
    SELECT
        'web' AS channel,
        ws.ws_order_number AS order_number,
        ws.ws_item_sk AS item_sk,
        ws.ws_sold_date_sk AS date_sk,
        COALESCE(ws.ws_net_paid, 0) AS net_paid,
        COALESCE(ws.ws_net_profit, 0) AS net_profit,
        COALESCE(ws.ws_ext_sales_price, 0) AS ext_sales_price,
        ws.ws_quantity AS quantity,
        CAST(NULL AS integer) AS cc_sk,
        CAST(NULL AS integer) AS store_sk,
        ws.ws_web_site_sk AS web_site_sk
    FROM web_sales ws
),
returns_unified AS (
    SELECT
        'catalog' AS channel,
        cr.cr_order_number AS order_number,
        cr.cr_item_sk AS item_sk,
        cr.cr_returned_date_sk AS date_sk,
        COALESCE(cr.cr_return_amount, 0) AS return_amount,
        COALESCE(cr.cr_net_loss, 0) AS net_loss,
        cr.cr_return_quantity AS return_quantity,
        cr.cr_call_center_sk AS cc_sk,
        CAST(NULL AS integer) AS store_sk,
        CAST(NULL AS integer) AS web_site_sk
    FROM catalog_returns cr
    UNION ALL
    SELECT
        'store' AS channel,
        sr.sr_ticket_number AS order_number,
        sr.sr_item_sk AS item_sk,
        sr.sr_returned_date_sk AS date_sk,
        COALESCE(sr.sr_return_amt, 0) AS return_amount,
        COALESCE(sr.sr_net_loss, 0) AS net_loss,
        sr.sr_return_quantity AS return_quantity,
        CAST(NULL AS integer) AS cc_sk,
        sr.sr_store_sk AS store_sk,
        CAST(NULL AS integer) AS web_site_sk
    FROM store_returns sr
    UNION ALL
    SELECT
        'web' AS channel,
        wr.wr_order_number AS order_number,
        wr.wr_item_sk AS item_sk,
        wr.wr_returned_date_sk AS date_sk,
        COALESCE(wr.wr_return_amt, 0) AS return_amount,
        COALESCE(wr.wr_net_loss, 0) AS net_loss,
        wr.wr_return_quantity AS return_quantity,
        CAST(NULL AS integer) AS cc_sk,
        CAST(NULL AS integer) AS store_sk,
        wr.wr_web_page_sk AS web_site_sk
    FROM web_returns wr
),
date_enriched AS (
    SELECT
        d.d_date_sk,
        d.d_year,
        d.d_month_seq,
        format_datetime(d.d_date, 'yyyy-MM') AS year_month,
        CASE WHEN d.d_weekend = 'Y' THEN TRUE ELSE FALSE END AS is_weekend
    FROM date_dim d
),
sales_with_dim AS (
    SELECT
        s.channel,
        s.order_number,
        s.item_sk,
        s.date_sk,
        de.year_month,
        de.d_year,
        de.is_weekend,
        s.net_paid,
        s.net_profit,
        s.ext_sales_price,
        s.quantity,
        s.cc_sk,
        s.store_sk,
        s.web_site_sk,
        CASE
            WHEN s.channel = 'catalog' THEN COALESCE(cc.cc_city, 'UNKNOWN')
            WHEN s.channel = 'store'   THEN COALESCE(st.s_city, 'UNKNOWN')
            WHEN s.channel = 'web'     THEN COALESCE(ws.web_site_id, 'UNKNOWN')
            ELSE 'UNKNOWN'
        END AS location_name
    FROM sales_unified s
    LEFT JOIN date_enriched de ON s.date_sk = de.d_date_sk
    LEFT JOIN call_center cc ON s.cc_sk = cc.cc_call_center_sk
    LEFT JOIN store st ON s.store_sk = st.s_store_sk
    LEFT JOIN web_site ws ON s.web_site_sk = ws.web_site_sk
),
returns_with_dim AS (
    SELECT
        r.channel,
        r.order_number,
        r.item_sk,
        r.date_sk,
        de.year_month,
        de.d_year,
        de.is_weekend,
        r.return_amount,
        r.net_loss,
        r.return_quantity,
        r.cc_sk,
        r.store_sk,
        r.web_site_sk
    FROM returns_unified r
    LEFT JOIN date_enriched de ON r.date_sk = de.d_date_sk
),
monthly_agg AS (
    SELECT
        s.channel,
        s.year_month,
        s.d_year,
        s.location_name,
        SUM(s.net_paid) AS total_net_paid,
        SUM(s.net_profit) AS total_net_profit,
        SUM(s.ext_sales_price) AS total_ext_sales,
        SUM(s.quantity) AS total_quantity,
        SUM(r.return_amount) FILTER (WHERE r.return_amount IS NOT NULL) AS total_return_amount,
        SUM(r.net_loss) FILTER (WHERE r.net_loss IS NOT NULL) AS total_return_loss,
        SUM(r.return_quantity) FILTER (WHERE r.return_quantity IS NOT NULL) AS total_return_qty,
        COUNT(DISTINCT s.order_number) AS distinct_orders,
        COUNT(DISTINCT s.item_sk) AS distinct_items
    FROM sales_with_dim s
    LEFT JOIN returns_with_dim r
      ON s.channel = r.channel
     AND s.order_number = r.order_number
     AND s.item_sk = r.item_sk
    GROUP BY
        s.channel,
        s.year_month,
        s.d_year,
        s.location_name
),
ranked_monthly AS (
    SELECT
        m.*,
        RANK() OVER (PARTITION BY m.channel ORDER BY m.total_net_paid DESC) AS net_paid_rank,
        SUM(m.total_net_paid) OVER (PARTITION BY m.channel ORDER BY m.year_month
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cum_net_paid,
        SUM(m.total_return_amount) OVER (PARTITION BY m.channel ORDER BY m.year_month
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cum_return_amount,
        (m.total_net_profit - m.total_return_loss) / NULLIF(m.total_net_paid, 0) AS profit_margin_adj,
        SUBSTR(m.location_name, 1, 3) || ':' || m.year_month AS loc_year_key,
        CASE WHEN m.total_return_amount > 0 THEN 'YES' ELSE 'NO' END AS has_returns
    FROM monthly_agg m
),
item_historic AS (
    SELECT
        i.i_item_sk,
        i.i_product_name,
        (SELECT AVG(cs.cs_net_profit)
         FROM catalog_sales cs
         WHERE cs.cs_item_sk = i.i_item_sk
           AND cs.cs_sold_date_sk BETWEEN (SELECT MAX(d.d_date_sk) - 365 FROM date_dim d)
                                     AND (SELECT MAX(d.d_date_sk) FROM date_dim d)
        ) AS avg_catalog_profit_last_year,
        (SELECT AVG(ss.ss_net_profit)
         FROM store_sales ss
         WHERE ss.ss_item_sk = i.i_item_sk
           AND ss.ss_sold_date_sk BETWEEN (SELECT MAX(d.d_date_sk) - 365 FROM date_dim d)
                                     AND (SELECT MAX(d.d_date_sk) FROM date_dim d)
        ) AS avg_store_profit_last_year,
        (SELECT AVG(ws.ws_net_profit)
         FROM web_sales ws
         WHERE ws.ws_item_sk = i.i_item_sk
           AND ws.ws_sold_date_sk BETWEEN (SELECT MAX(d.d_date_sk) - 365 FROM date_dim d)
                                    AND (SELECT MAX(d.d_date_sk) FROM date_dim d)
        ) AS avg_web_profit_last_year
    FROM item i
    WHERE i.i_current_price IS NOT NULL
),
final AS (
    SELECT
        r.channel,
        r.year_month,
        r.location_name,
        r.total_net_paid,
        r.total_net_profit,
        r.total_ext_sales,
        r.total_quantity,
        r.total_return_amount,
        r.total_return_qty,
        r.distinct_orders,
        r.distinct_items,
        r.net_paid_rank,
        r.cum_net_paid,
        r.cum_return_amount,
        r.profit_margin_adj,
        r.loc_year_key,
        r.has_returns,
        NULL AS placeholder
    FROM ranked_monthly r
    WHERE r.total_net_paid > 0 OR r.total_return_amount > 0
    UNION ALL
    SELECT
        'summary' AS channel,
        'ALL' AS year_month,
        'ALL' AS location_name,
        SUM(total_net_paid) AS total_net_paid,
        SUM(total_net_profit) AS total_net_profit,
        SUM(total_ext_sales) AS total_ext_sales,
        SUM(total_quantity) AS total_quantity,
        SUM(total_return_amount) AS total_return_amount,
        SUM(total_return_qty) AS total_return_qty,
        SUM(distinct_orders) AS distinct_orders,
        SUM(distinct_items) AS distinct_items,
        NULL AS net_paid_rank,
        SUM(cum_net_paid) AS cum_net_paid,
        SUM(cum_return_amount) AS cum_return_amount,
        NULL AS profit_margin_adj,
        'SUMMARY:ALL' AS loc_year_key,
        CASE WHEN SUM(total_return_amount) > 0 THEN 'YES' ELSE 'NO' END AS has_returns,
        NULL AS placeholder
    FROM ranked_monthly
)
SELECT
    f.channel,
    f.year_month,
    f.location_name,
    f.total_net_paid,
    f.total_net_profit,
    ROUND(f.profit_margin_adj, 4) AS profit_margin_adj,
    f.loc_year_key,
    f.has_returns,
    (SELECT i.i_product_name
     FROM item i
     JOIN sales_with_dim s2 ON i.i_item_sk = s2.item_sk
     WHERE s2.channel = f.channel
       AND s2.year_month = f.year_month
     GROUP BY i.i_item_sk, i.i_product_name
     ORDER BY SUM(s2.net_profit) DESC
     LIMIT 1) AS top_product_name
FROM final f
WHERE f.channel IS NOT NULL
ORDER BY f.channel, f.year_month DESC, f.total_net_paid DESC
LIMIT 100
