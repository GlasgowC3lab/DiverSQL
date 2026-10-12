SELECT i_item_sk,
       i_item_id,
       profit_level
FROM (
        (
            SELECT i.i_item_sk AS i_item_sk,
                   i.i_item_id AS i_item_id,
                   CASE WHEN cs.cs_net_profit > 1000 THEN 'High' ELSE 'Low' END AS profit_level
            FROM catalog_sales cs
            JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
            JOIN item i ON cs.cs_item_sk = i.i_item_sk
            WHERE d.d_year = 2022
              AND cs.cs_net_profit > 0
        )
        INTERSECT
        (
            SELECT i.i_item_sk AS i_item_sk,
                   i.i_item_id AS i_item_id,
                   CASE WHEN cs.cs_quantity > 5 THEN 'High' ELSE 'Low' END AS profit_level
            FROM catalog_sales cs
            JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
            JOIN item i ON cs.cs_item_sk = i.i_item_sk
            WHERE d.d_year = 2022
              AND cs.cs_quantity > 5
        )
    )
EXCEPT
(
    SELECT i.i_item_sk AS i_item_sk,
           i.i_item_id AS i_item_id,
           CASE WHEN cr.cr_return_amount > 0 THEN 'Returned' ELSE 'NotReturned' END AS profit_level
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    WHERE d.d_year = 2022
)
ORDER BY profit_level DESC,
         i_item_id
LIMIT 100
