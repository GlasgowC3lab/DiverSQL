WITH combined AS (
    SELECT d.d_year AS d_year,
           d.d_month_seq AS d_month_seq,
           ca.ca_state AS state,
           cs.cs_net_paid AS net_paid,
           cs.cs_net_profit AS net_profit,
           CAST(0.0 AS decimal(7,2)) AS loss
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk

    UNION ALL

    SELECT d.d_year,
           d.d_month_seq,
           ca.ca_state,
           ss.ss_net_paid,
           ss.ss_net_profit,
           CAST(0.0 AS decimal(7,2))
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk

    UNION ALL

    SELECT d.d_year,
           d.d_month_seq,
           ca.ca_state,
           ws.ws_net_paid,
           ws.ws_net_profit,
           CAST(0.0 AS decimal(7,2))
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk

    UNION ALL

    SELECT d.d_year,
           d.d_month_seq,
           ca.ca_state,
           CAST(0.0 AS decimal(7,2)),
           CAST(0.0 AS decimal(7,2)),
           cr.cr_net_loss
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk

    UNION ALL

    SELECT d.d_year,
           d.d_month_seq,
           ca.ca_state,
           CAST(0.0 AS decimal(7,2)),
           CAST(0.0 AS decimal(7,2)),
           sr.sr_net_loss
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk

    UNION ALL

    SELECT d.d_year,
           d.d_month_seq,
           ca.ca_state,
           CAST(0.0 AS decimal(7,2)),
           CAST(0.0 AS decimal(7,2)),
           wr.wr_net_loss
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN customer_address ca ON wr.wr_refunded_addr_sk = ca.ca_address_sk
)
SELECT d_year,
       d_month_seq,
       state,
       sum(net_paid) AS total_net_paid,
       sum(net_profit) AS total_net_profit,
       sum(loss) AS total_loss,
       sum(net_paid) - sum(loss) AS net_sales,
       avg(net_paid) AS avg_net_paid,
       count_if(net_paid > 0) AS sales_transactions,
       count_if(loss > 0) AS return_transactions
FROM combined
WHERE d_year = 2000
GROUP BY d_year, d_month_seq, state
ORDER BY d_year, d_month_seq, state
