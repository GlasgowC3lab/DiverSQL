WITH aggregated_returns AS (
    SELECT
        d_open.d_fy_year,
        d_open.d_fy_quarter_seq,
        i.i_brand,
        s.s_division_name,
        s.s_tax_percentage,
        ws.web_name,
        ws.web_tax_percentage,
        date_diff('day', any_value(d_open.d_date), any_value(d_close.d_date)) AS website_active_days,
        SUM(wr.wr_return_amt) AS total_return_amt,
        SUM(wr.wr_net_loss) AS total_net_loss,
        COUNT(*) AS return_cnt,
        AVG(wr.wr_return_quantity) AS avg_return_qty
    FROM date_dim d_open
    JOIN web_returns wr
        ON wr.wr_returned_date_sk = d_open.d_date_sk
    JOIN item i
        ON i.i_item_sk = wr.wr_item_sk
    JOIN store s
        ON s.s_closed_date_sk = d_open.d_date_sk
    JOIN web_site ws
        ON ws.web_open_date_sk = d_open.d_date_sk
    JOIN date_dim d_close
        ON ws.web_close_date_sk = d_close.d_date_sk
    WHERE d_open.d_fy_year BETWEEN 2020 AND 2023
      AND i.i_brand IS NOT NULL
    GROUP BY
        d_open.d_fy_year,
        d_open.d_fy_quarter_seq,
        i.i_brand,
        s.s_division_name,
        s.s_tax_percentage,
        ws.web_name,
        ws.web_tax_percentage
)
SELECT
    d_fy_year,
    d_fy_quarter_seq,
    i_brand,
    s_division_name,
    s_tax_percentage,
    web_name,
    web_tax_percentage,
    website_active_days,
    total_return_amt,
    total_net_loss,
    return_cnt,
    avg_return_qty,
    RANK() OVER (PARTITION BY d_fy_year ORDER BY total_net_loss DESC) AS loss_rank
FROM aggregated_returns
ORDER BY total_net_loss DESC
LIMIT 100
