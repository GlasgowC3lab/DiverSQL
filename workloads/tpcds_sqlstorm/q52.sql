WITH
sales_union AS (
   SELECT ss_sold_date_sk AS date_sk,
          'store' AS channel,
          ss_item_sk AS item_sk,
          ss_quantity AS quantity,
          ss_net_profit AS profit,
          ss_net_paid AS net_paid,
          ss_ext_discount_amt AS discount
   FROM store_sales
   UNION ALL
   SELECT cs_sold_date_sk,
          'catalog',
          cs_item_sk,
          cs_quantity,
          cs_net_profit,
          cs_net_paid,
          cs_ext_discount_amt
   FROM catalog_sales
   UNION ALL
   SELECT ws_sold_date_sk,
          'web',
          ws_item_sk,
          ws_quantity,
          ws_net_profit,
          ws_net_paid,
          ws_ext_discount_amt
   FROM web_sales
),
returns_union AS (
   SELECT sr_returned_date_sk AS date_sk,
          'store' AS channel,
          sr_item_sk AS item_sk,
          sr_return_quantity AS quantity,
          sr_net_loss AS loss
   FROM store_returns
   UNION ALL
   SELECT cr_returned_date_sk,
          'catalog',
          cr_item_sk,
          cr_return_quantity,
          cr_net_loss
   FROM catalog_returns
   UNION ALL
   SELECT wr_returned_date_sk,
          'web',
          wr_item_sk,
          wr_return_quantity,
          wr_net_loss
   FROM web_returns
),
sales_agg AS (
   SELECT su.date_sk,
          su.channel,
          su.item_sk,
          i.i_category,
          i.i_product_name,
          SUM(su.profit) AS total_profit,
          SUM(su.quantity) AS total_quantity,
          SUM(su.net_paid) AS total_net_paid,
          SUM(su.discount) AS total_discount
   FROM sales_union su
   JOIN item i ON su.item_sk = i.i_item_sk
   GROUP BY su.date_sk, su.channel, su.item_sk, i.i_category, i.i_product_name
),
returns_agg AS (
   SELECT ru.date_sk,
          ru.channel,
          ru.item_sk,
          SUM(ru.loss) AS total_loss,
          SUM(ru.quantity) AS total_return_qty
   FROM returns_union ru
   GROUP BY ru.date_sk, ru.channel, ru.item_sk
),
combined AS (
   SELECT s.date_sk,
          s.channel,
          s.item_sk,
          s.i_category,
          s.i_product_name,
          s.total_profit - COALESCE(r.total_loss, 0) AS net_profit,
          s.total_quantity - COALESCE(r.total_return_qty, 0) AS net_quantity,
          s.total_net_paid - COALESCE(r.total_loss, 0) AS net_paid,
          s.total_discount
   FROM sales_agg s
   LEFT JOIN returns_agg r
          ON s.date_sk = r.date_sk
          AND s.channel = r.channel
          AND s.item_sk = r.item_sk
),
final AS (
   SELECT d.d_date,
          c.channel,
          c.i_category,
          c.i_product_name,
          c.net_profit,
          c.net_quantity,
          c.net_paid,
          c.total_discount,
          SUM(c.net_profit) OVER (PARTITION BY c.channel, c.i_category ORDER BY d.d_date ROWS BETWEEN 30 PRECEDING AND CURRENT ROW) AS moving_30d_profit,
          RANK() OVER (PARTITION BY d.d_date ORDER BY c.net_profit DESC) AS profit_rank
   FROM combined c
   JOIN date_dim d ON c.date_sk = d.d_date_sk
   WHERE d.d_year BETWEEN 1998 AND 2000
)
SELECT d_date,
       channel,
       i_category,
       i_product_name,
       net_profit,
       net_quantity,
       net_paid,
       total_discount,
       moving_30d_profit,
       profit_rank
FROM final
ORDER BY d_date, channel, profit_rank
LIMIT 1000
