SELECT
    cp.cp_department,
    COUNT(*) AS return_cnt,
    SUM(wr.wr_return_amt) AS total_return_amt,
    SUM(wr.wr_net_loss) AS total_net_loss,
    AVG(wr.wr_net_loss) AS avg_net_loss,
    SUM(wr.wr_return_quantity) AS total_quantity,
    SUM(wr.wr_return_amt) / NULLIF(SUM(wr.wr_return_quantity), 0) AS avg_return_amt_per_item,
    RANK() OVER (ORDER BY SUM(wr.wr_return_amt) DESC) AS dept_return_amt_rank
FROM
    catalog_page cp
JOIN
    web_returns wr
    ON wr.wr_returned_date_sk BETWEEN cp.cp_start_date_sk AND cp.cp_end_date_sk
WHERE
    cp.cp_catalog_page_number IN (1, 2, 3)
    AND wr.wr_return_quantity > 0
    AND cp.cp_type IS NOT NULL
GROUP BY
    cp.cp_department
HAVING
    SUM(wr.wr_return_amt) > 1000
ORDER BY
    total_return_amt DESC
LIMIT 10
