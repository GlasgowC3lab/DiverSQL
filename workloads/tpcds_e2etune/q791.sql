WITH returns_agg AS (
    SELECT
        i.i_category AS i_category,
        d.d_year AS d_year,
        d.d_month_seq AS month_seq,
        SUM(cr.cr_net_loss) AS total_return_loss,
        SUM(cr.cr_return_quantity) AS total_return_qty
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE r.r_reason_desc IN ('Damaged', 'Defective')
      AND d.d_year BETWEEN 2000 AND 2002
      AND cr.cr_refunded_hdemo_sk IN (6189, 2480, 3797)
    GROUP BY i.i_category, d.d_year, d.d_month_seq
),
sales_agg AS (
    SELECT
        i.i_category AS i_category,
        d.d_year AS d_year,
        d.d_month_seq AS month_seq,
        SUM(ws.ws_net_profit) AS total_sales_profit,
        SUM(ws.ws_quantity) AS total_sales_qty
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
      AND ws.ws_ship_hdemo_sk IN (6189, 2480, 3797)
    GROUP BY i.i_category, d.d_year, d.d_month_seq
)
SELECT
    r.i_category,
    r.d_year,
    r.month_seq,
    r.total_return_loss,
    s.total_sales_profit,
    (s.total_sales_profit - r.total_return_loss) AS net_margin,
    RANK() OVER (PARTITION BY r.d_year ORDER BY (s.total_sales_profit - r.total_return_loss) DESC) AS category_rank
FROM returns_agg r
JOIN sales_agg s
  ON r.i_category = s.i_category
  AND r.d_year = s.d_year
  AND r.month_seq = s.month_seq
ORDER BY r.d_year, net_margin DESC
LIMIT 100
