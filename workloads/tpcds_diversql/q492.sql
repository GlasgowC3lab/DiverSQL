WITH sampled_catalog AS (
    SELECT *
    FROM catalog_sales
    TABLESAMPLE BERNOULLI (10)
)
SELECT item_id,
       amount,
       source
FROM (
    SELECT i.i_item_id AS item_id,
           SUM(sc.cs_ext_sales_price) AS amount,
           'catalog' AS source
    FROM sampled_catalog sc
    JOIN item i
      ON sc.cs_item_sk = i.i_item_sk
    JOIN date_dim d
      ON sc.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2002
      AND sc.cs_ext_sales_price > (
            SELECT MAX(cs.cs_net_paid)
            FROM catalog_sales cs
            WHERE cs.cs_sold_date_sk = 2451910
          )
    GROUP BY i.i_item_id

    UNION

    SELECT COALESCE(i_return.i_item_id, i_sale.i_item_id) AS item_id,
           COALESCE(SUM(sr.sr_return_amt), 0) - COALESCE(SUM(ss.ss_net_paid), 0) AS amount,
           'returns' AS source
    FROM store_sales ss
    FULL OUTER JOIN store_returns sr
      ON ss.ss_ticket_number = sr.sr_ticket_number
     AND ss.ss_item_sk = sr.sr_item_sk
    LEFT JOIN item i_sale
      ON ss.ss_item_sk = i_sale.i_item_sk
    LEFT JOIN item i_return
      ON sr.sr_item_sk = i_return.i_item_sk
    WHERE (ss.ss_sold_date_sk = 2451910 OR sr.sr_returned_date_sk = 2451910)
    GROUP BY COALESCE(i_return.i_item_id, i_sale.i_item_id)
) AS combined
ORDER BY amount DESC
LIMIT 100
