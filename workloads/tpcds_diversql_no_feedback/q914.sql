WITH per_page AS (
    SELECT
        wp.wp_web_page_sk,
        wp.wp_type,
        COUNT(*) AS return_cnt,
        SUM(wr.wr_return_amt) AS total_return_amt,
        AVG(wr.wr_return_tax) AS avg_return_tax,
        SUM(wr.wr_net_loss) AS total_net_loss
    FROM web_returns wr
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE wp.wp_image_count > 2
      AND wp.wp_rec_end_date BETWEEN DATE '1999-01-01' AND DATE '2001-12-31'
      AND wr.wr_return_amt > 100
    GROUP BY wp.wp_web_page_sk, wp.wp_type
),
overall AS (
    SELECT
        wp_type,
        SUM(return_cnt) AS total_returns,
        SUM(total_return_amt) AS grand_return_amt,
        AVG(total_net_loss) AS avg_net_loss
    FROM per_page
    GROUP BY wp_type
),
high AS (
    SELECT wp_type, total_returns, grand_return_amt, avg_net_loss
    FROM overall
    WHERE total_returns >= 5
      AND grand_return_amt > 500
      AND avg_net_loss < 200
),
low AS (
    SELECT wp_type, total_returns, grand_return_amt, avg_net_loss
    FROM overall
    WHERE total_returns < 5
),
 diff AS (
    SELECT wp_type, total_returns, grand_return_amt, avg_net_loss
    FROM high
    EXCEPT
    SELECT wp_type, total_returns, grand_return_amt, avg_net_loss
    FROM low
)
SELECT
    d.wp_type,
    d.total_returns,
    d.grand_return_amt,
    d.avg_net_loss,
    ROW_NUMBER() OVER (PARTITION BY d.wp_type ORDER BY d.grand_return_amt DESC) AS rn
FROM diff d
ORDER BY d.grand_return_amt DESC
LIMIT 100
