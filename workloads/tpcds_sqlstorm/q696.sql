WITH
date_filter AS (
    SELECT d_date_sk, d_date
    FROM date_dim
    WHERE d_year = (SELECT max(d_year) FROM date_dim) - 1
      AND d_holiday = 'N'
),
sales_agg AS (
    SELECT ss_sold_date_sk AS date_sk,
           'store' AS channel,
           SUM(ss_net_profit) AS net_profit,
           SUM(ss_net_paid) AS net_paid,
           COUNT(*) AS sales_cnt
    FROM store_sales ss
    JOIN date_filter df ON ss.ss_sold_date_sk = df.d_date_sk
    GROUP BY ss_sold_date_sk
    UNION ALL
    SELECT ws_sold_date_sk AS date_sk,
           'web' AS channel,
           SUM(ws_net_profit) AS net_profit,
           SUM(ws_net_paid) AS net_paid,
           COUNT(*) AS sales_cnt
    FROM web_sales ws
    JOIN date_filter df ON ws.ws_sold_date_sk = df.d_date_sk
    GROUP BY ws_sold_date_sk
    UNION ALL
    SELECT cs_sold_date_sk AS date_sk,
           'catalog' AS channel,
           SUM(cs_net_profit) AS net_profit,
           SUM(cs_net_paid) AS net_paid,
           COUNT(*) AS sales_cnt
    FROM catalog_sales cs
    JOIN date_filter df ON cs.cs_sold_date_sk = df.d_date_sk
    GROUP BY cs_sold_date_sk
),
returns_agg AS (
    SELECT sr_returned_date_sk AS date_sk,
           'store' AS channel,
           SUM(sr_net_loss) AS net_loss,
           COUNT(*) AS return_cnt
    FROM store_returns sr
    JOIN date_filter df ON sr.sr_returned_date_sk = df.d_date_sk
    GROUP BY sr.sr_returned_date_sk
    UNION ALL
    SELECT wr_returned_date_sk AS date_sk,
           'web' AS channel,
           SUM(wr_net_loss) AS net_loss,
           COUNT(*) AS return_cnt
    FROM web_returns wr
    JOIN date_filter df ON wr.wr_returned_date_sk = df.d_date_sk
    GROUP BY wr.wr_returned_date_sk
    UNION ALL
    SELECT cr_returned_date_sk AS date_sk,
           'catalog' AS channel,
           SUM(cr_net_loss) AS net_loss,
           COUNT(*) AS return_cnt
    FROM catalog_returns cr
    JOIN date_filter df ON cr.cr_returned_date_sk = df.d_date_sk
    GROUP BY cr.cr_returned_date_sk
),
joined AS (
    SELECT
        s.date_sk,
        d.d_date,
        s.channel,
        s.net_profit,
        s.net_paid,
        s.sales_cnt,
        COALESCE(r.net_loss, 0) AS net_loss,
        COALESCE(r.return_cnt, 0) AS return_cnt,
        (s.net_profit - COALESCE(r.net_loss, 0)) AS adj_profit,
        CASE
            WHEN (s.net_profit - COALESCE(r.net_loss, 0)) > 0 THEN 'POSITIVE'
            WHEN (s.net_profit - COALESCE(r.net_loss, 0)) < 0 THEN 'NEGATIVE'
            ELSE 'ZERO'
        END AS profit_flag,
        SUM(s.net_profit - COALESCE(r.net_loss, 0)) OVER (PARTITION BY s.channel ORDER BY d.d_date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_adj_profit,
        RANK() OVER (PARTITION BY s.channel ORDER BY (s.net_profit - COALESCE(r.net_loss, 0)) DESC) AS profit_rank,
        CONCAT('Channel: ', s.channel, ' on ', CAST(d.d_date AS VARCHAR)) AS description,
        CASE WHEN s.sales_cnt = 0 THEN NULL ELSE (s.net_profit - COALESCE(r.net_loss, 0)) / nullif(s.sales_cnt, 0) END AS profit_per_sale,
        (SELECT AVG(ss2.ss_net_profit)
         FROM store_sales ss2
         WHERE ss2.ss_sold_date_sk = s.date_sk
           AND EXISTS (
               SELECT 1 FROM item i2
               WHERE i2.i_item_sk = ss2.ss_item_sk
                 AND i2.i_color = 'BLACK'
           )
        ) AS avg_store_profit_for_black_items
    FROM sales_agg s
    LEFT JOIN returns_agg r ON s.date_sk = r.date_sk AND s.channel = r.channel
    JOIN date_filter d ON s.date_sk = d.d_date_sk
),
call_center_filtered AS (
    SELECT
        cc_call_center_sk,
        cc_name,
        COALESCE(cc_city, 'UNKNOWN') AS city,
        COALESCE(cc_state, 'UNKNOWN') AS state,
        cc_gmt_offset,
        cc_tax_percentage,
        length(cc_name) AS name_len,
        (length(cc_name) % 3) AS mod3
    FROM call_center
    WHERE cc_closed_date_sk IS NULL
      AND (cc_tax_percentage IS NOT NULL OR cc_gmt_offset IS NOT NULL)
),
final AS (
    SELECT
        j.date_sk,
        j.d_date,
        j.channel,
        j.adj_profit,
        j.running_adj_profit,
        j.profit_rank,
        j.profit_flag,
        j.description,
        j.profit_per_sale,
        j.avg_store_profit_for_black_items,
        cc.cc_call_center_sk,
        cc.cc_name,
        CONCAT(cc.cc_name, ' - ', cc.city, ', ', cc.state) AS call_center_desc,
        CASE
            WHEN cc.cc_tax_percentage = 0 THEN NULL
            ELSE (j.adj_profit / nullif(cc.cc_tax_percentage, 0))
        END AS profit_tax_ratio
    FROM joined j
    LEFT JOIN call_center_filtered cc
      ON (cc.name_len % length(j.channel) = 0) AND (cc.mod3 = j.profit_rank % 3)
)
SELECT *
FROM final
WHERE profit_flag = 'POSITIVE'
   OR (profit_per_sale IS NOT NULL AND profit_per_sale > 1000)
ORDER BY date_sk ASC, channel
