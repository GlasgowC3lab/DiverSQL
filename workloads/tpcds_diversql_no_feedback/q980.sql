WITH returns_agg AS (
    SELECT
        wr_item_sk,
        wr_web_page_sk,
        SUM(wr_return_quantity) AS total_qty,
        SUM(wr_return_amt) AS total_return_amt,
        AVG(wr_return_amt) AS avg_return_amt,
        SUM(wr_reversed_charge) AS total_rev_charge
    FROM web_returns
    WHERE wr_return_amt > 50
      AND wr_reversed_charge BETWEEN 10 AND 400
      AND wr_return_quantity >= 1
      AND wr_return_quantity <= 5
      AND wr_returned_time_sk >= 0
    GROUP BY wr_item_sk, wr_web_page_sk
),
joined AS (
    SELECT
        i.i_manager_id,
        i.i_category_id,
        i.i_product_name,
        wp.wp_autogen_flag,
        wp.wp_image_count,
        wp.wp_rec_start_date,
        ra.total_qty,
        ra.total_return_amt,
        ra.avg_return_amt,
        ra.total_rev_charge
    FROM returns_agg ra
    JOIN item i
      ON ra.wr_item_sk = i.i_item_sk
    JOIN web_page wp
      ON ra.wr_web_page_sk = wp.wp_web_page_sk
    WHERE i.i_manager_id IN (21, 40)
      AND i.i_category_id = 1
      AND wp.wp_autogen_flag = 'N'
      AND wp.wp_image_count BETWEEN 1 AND 5
      AND wp.wp_rec_start_date >= DATE '1999-01-01'
      AND wp.wp_rec_start_date <= DATE '2000-12-31'
)
SELECT
    d.threshold,
    j.i_manager_id,
    j.i_category_id,
    SUM(j.total_return_amt) AS sum_return_amt,
    AVG(j.avg_return_amt) AS avg_of_avg_return,
    SUM(j.total_rev_charge) AS sum_rev_charge
FROM joined j
CROSS JOIN (VALUES 100, 200, 300) AS d(threshold)
WHERE j.total_return_amt > d.threshold
GROUP BY d.threshold, j.i_manager_id, j.i_category_id
HAVING SUM(j.total_qty) > 10
ORDER BY d.threshold DESC, sum_return_amt DESC
