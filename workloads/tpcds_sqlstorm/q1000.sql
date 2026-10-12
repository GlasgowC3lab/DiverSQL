WITH combined AS (
    SELECT
        d.d_year,
        d.d_moy AS month_num,
        ca.ca_state AS state,
        cd.cd_gender AS gender,
        ss.ss_net_paid AS sales_amount,
        ss.ss_net_profit AS profit_amount,
        CAST(0 AS decimal(7,2)) AS return_amount,
        CAST(0 AS decimal(7,2)) AS loss_amount
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk

    UNION ALL

    SELECT
        d.d_year,
        d.d_moy,
        ca.ca_state,
        cd.cd_gender,
        cs.cs_net_paid,
        cs.cs_net_profit,
        CAST(0 AS decimal(7,2)),
        CAST(0 AS decimal(7,2))
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk

    UNION ALL

    SELECT
        d.d_year,
        d.d_moy,
        ca.ca_state,
        cd.cd_gender,
        ws.ws_net_paid,
        ws.ws_net_profit,
        CAST(0 AS decimal(7,2)),
        CAST(0 AS decimal(7,2))
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk

    UNION ALL

    SELECT
        d.d_year,
        d.d_moy,
        ca.ca_state,
        cd.cd_gender,
        CAST(0 AS decimal(7,2)),
        CAST(0 AS decimal(7,2)),
        sr.sr_return_amt,
        sr.sr_net_loss
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk

    UNION ALL

    SELECT
        d.d_year,
        d.d_moy,
        ca.ca_state,
        cd.cd_gender,
        CAST(0 AS decimal(7,2)),
        CAST(0 AS decimal(7,2)),
        cr.cr_return_amount,
        cr.cr_net_loss
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk

    UNION ALL

    SELECT
        d.d_year,
        d.d_moy,
        ca.ca_state,
        cd.cd_gender,
        CAST(0 AS decimal(7,2)),
        CAST(0 AS decimal(7,2)),
        wr.wr_return_amt,
        wr.wr_net_loss
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN customer c ON wr.wr_refunded_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON wr.wr_refunded_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
agg AS (
    SELECT
        d_year,
        month_num,
        state,
        gender,
        sum(sales_amount) AS total_sales,
        sum(profit_amount) AS total_profit,
        sum(return_amount) AS total_returns,
        sum(loss_amount) AS total_loss,
        CASE WHEN sum(sales_amount) = 0 THEN NULL ELSE sum(profit_amount) / sum(sales_amount) END AS profit_margin,
        sum(sales_amount) - sum(return_amount) AS net_sales,
        sum(profit_amount) - sum(loss_amount) AS net_profit
    FROM combined
    GROUP BY d_year, month_num, state, gender
    HAVING sum(sales_amount) + sum(return_amount) > 0
),
final AS (
    SELECT
        *,
        sum(total_sales) OVER (PARTITION BY state, gender ORDER BY d_year, month_num ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_sales,
        sum(total_profit) OVER (PARTITION BY state, gender ORDER BY d_year, month_num ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_profit
    FROM agg
)
SELECT
    d_year,
    month_num AS month,
    state,
    gender,
    round(total_sales, 2) AS total_sales,
    round(total_profit, 2) AS total_profit,
    round(total_returns, 2) AS total_returns,
    round(total_loss, 2) AS total_loss,
    round(profit_margin, 4) AS profit_margin,
    round(net_sales, 2) AS net_sales,
    round(net_profit, 2) AS net_profit,
    round(cumulative_sales, 2) AS cumulative_sales,
    round(cumulative_profit, 2) AS cumulative_profit
FROM final
ORDER BY d_year, month, state, gender
LIMIT 200
