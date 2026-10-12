WITH intersect_items AS (
    SELECT cr.cr_item_sk AS item_sk
    FROM catalog_returns cr
    JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
    WHERE t.t_hour BETWEEN 8 AND 12
    INTERSECT
    SELECT ws.ws_item_sk AS item_sk
    FROM web_sales ws
    JOIN time_dim t2 ON ws.ws_sold_time_sk = t2.t_time_sk
    WHERE t2.t_hour BETWEEN 8 AND 12
)
SELECT
    i.i_item_id,
    i.i_brand,
    COALESCE(r.total_return_qty, 0) AS total_return_qty,
    COALESCE(s.total_sales_qty, 0) AS total_sales_qty,
    CASE
        WHEN COALESCE(r.total_return_qty, 0) > COALESCE(s.total_sales_qty, 0) THEN 'More Returns'
        ELSE 'More Sales'
    END AS return_sales_balance,
    ROW_NUMBER() OVER (ORDER BY COALESCE(r.total_return_qty, 0) DESC) AS rn
FROM intersect_items ii
JOIN item i ON ii.item_sk = i.i_item_sk
LEFT JOIN (
    SELECT cr.cr_item_sk, SUM(cr.cr_return_quantity) AS total_return_qty
    FROM catalog_returns cr
    JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
    WHERE t.t_hour BETWEEN 8 AND 12
    GROUP BY cr.cr_item_sk
) r ON i.i_item_sk = r.cr_item_sk
LEFT JOIN (
    SELECT ws.ws_item_sk, SUM(ws.ws_quantity) AS total_sales_qty
    FROM web_sales ws
    JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    WHERE t.t_hour BETWEEN 8 AND 12
    GROUP BY ws.ws_item_sk
) s ON i.i_item_sk = s.ws_item_sk
ORDER BY total_return_qty DESC, i.i_item_id
