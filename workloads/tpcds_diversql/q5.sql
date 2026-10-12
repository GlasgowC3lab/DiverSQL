SELECT
    wp.wp_url,
    wp.wp_char_count,
    SUM(wr.wr_return_amt) AS total_return_amount,
    COUNT(*) AS returns_count
FROM
    web_page wp
JOIN
    web_returns wr
    ON wr.wr_web_page_sk = wp.wp_web_page_sk
WHERE
    wp.wp_url LIKE 'http://www.foo.com%'
    AND wp.wp_char_count > 3000
    AND wr.wr_return_quantity > 1
GROUP BY
    wp.wp_url,
    wp.wp_char_count
ORDER BY
    total_return_amount DESC
LIMIT 10
