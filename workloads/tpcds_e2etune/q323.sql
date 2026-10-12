WITH page_returns AS (
    SELECT
        wr.wr_web_page_sk,
        SUM(wr.wr_net_loss) AS total_net_loss,
        AVG(wr.wr_return_amt) AS avg_return_amt,
        SUM(wr.wr_return_quantity) AS total_return_qty,
        COUNT(DISTINCT wr.wr_returning_customer_sk) AS distinct_customers,
        COUNT(*) AS total_returns
    FROM web_returns wr
    WHERE wr.wr_returned_date_sk BETWEEN 2450000 AND 2452000
    GROUP BY wr.wr_web_page_sk
    HAVING COUNT(*) >= 100
)
SELECT
    wp.wp_url,
    wp.wp_type,
    pr.total_net_loss,
    pr.avg_return_amt,
    pr.total_return_qty,
    pr.distinct_customers,
    RANK() OVER (ORDER BY pr.total_net_loss DESC) AS net_loss_rank
FROM page_returns pr
JOIN web_page wp
    ON pr.wr_web_page_sk = wp.wp_web_page_sk
ORDER BY pr.total_net_loss DESC
LIMIT 5
