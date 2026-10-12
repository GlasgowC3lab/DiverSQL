WITH sales_union AS (
    SELECT
        ss_sold_date_sk AS date_sk,
        ss_item_sk AS item_sk,
        ss_cdemo_sk AS cdemo_sk,
        ss_customer_sk AS customer_sk,
        ss_ticket_number AS order_number,
        ss_net_paid AS net_paid,
        ss_net_profit AS net_profit,
        ss_quantity AS quantity,
        ss_ext_discount_amt AS discount_amt,
        ss_promo_sk AS promo_sk,
        'store' AS channel
    FROM store_sales
    UNION ALL
    SELECT
        cs_sold_date_sk,
        cs_item_sk,
        cs_bill_cdemo_sk,
        cs_bill_customer_sk,
        cs_order_number,
        cs_net_paid,
        cs_net_profit,
        cs_quantity,
        cs_ext_discount_amt,
        cs_promo_sk,
        'catalog'
    FROM catalog_sales
    UNION ALL
    SELECT
        ws_sold_date_sk,
        ws_item_sk,
        ws_bill_cdemo_sk,
        ws_bill_customer_sk,
        ws_order_number,
        ws_net_paid,
        ws_net_profit,
        ws_quantity,
        ws_ext_discount_amt,
        ws_promo_sk,
        'web'
    FROM web_sales
),
sales_data AS (
    SELECT
        d.d_year AS year,
        i.i_brand AS brand,
        coalesce(cd.cd_gender, 'UNKNOWN') AS gender,
        s.channel,
        sum(s.net_paid) AS total_net_paid,
        sum(s.net_profit) AS total_net_profit,
        sum(s.quantity) AS total_quantity,
        sum(s.discount_amt) AS total_discount_amount,
        count(distinct s.order_number) AS distinct_orders,
        count(distinct s.customer_sk) AS distinct_customers
    FROM sales_union s
    JOIN date_dim d ON s.date_sk = d.d_date_sk
    JOIN item i ON s.item_sk = i.i_item_sk
    LEFT JOIN customer_demographics cd ON s.cdemo_sk = cd.cd_demo_sk
    GROUP BY d.d_year, i.i_brand, coalesce(cd.cd_gender, 'UNKNOWN'), s.channel
),
returns_union AS (
    SELECT
        sr_returned_date_sk AS date_sk,
        sr_item_sk AS item_sk,
        sr_cdemo_sk AS cdemo_sk,
        sr_return_amt AS return_amount,
        sr_return_quantity AS return_quantity,
        sr_net_loss AS net_loss,
        'store' AS channel
    FROM store_returns
    UNION ALL
    SELECT
        cr_returned_date_sk,
        cr_item_sk,
        cr_refunded_cdemo_sk,
        cr_return_amount,
        cr_return_quantity,
        cr_net_loss,
        'catalog'
    FROM catalog_returns
    UNION ALL
    SELECT
        wr_returned_date_sk,
        wr_item_sk,
        wr_refunded_cdemo_sk,
        wr_return_amt,
        wr_return_quantity,
        wr_net_loss,
        'web'
    FROM web_returns
),
returns_data AS (
    SELECT
        d.d_year AS year,
        i.i_brand AS brand,
        coalesce(cd.cd_gender, 'UNKNOWN') AS gender,
        r.channel,
        sum(r.return_amount) AS total_return_amount,
        sum(r.return_quantity) AS total_return_quantity,
        sum(r.net_loss) AS total_net_loss,
        count(*) AS return_transactions
    FROM returns_union r
    JOIN date_dim d ON r.date_sk = d.d_date_sk
    JOIN item i ON r.item_sk = i.i_item_sk
    LEFT JOIN customer_demographics cd ON r.cdemo_sk = cd.cd_demo_sk
    GROUP BY d.d_year, i.i_brand, coalesce(cd.cd_gender, 'UNKNOWN'), r.channel
),
combined AS (
    SELECT
        s.year,
        s.brand,
        s.gender,
        s.channel,
        s.total_net_paid,
        s.total_net_profit,
        s.total_quantity,
        s.total_discount_amount,
        s.distinct_orders,
        s.distinct_customers,
        coalesce(r.total_return_amount, 0) AS total_return_amount,
        coalesce(r.total_return_quantity, 0) AS total_return_quantity,
        coalesce(r.total_net_loss, 0) AS total_net_loss,
        coalesce(r.return_transactions, 0) AS return_transactions,
        CASE WHEN s.total_net_paid > 0 THEN coalesce(r.total_return_amount, 0) / s.total_net_paid ELSE NULL END AS return_rate,
        CASE WHEN s.total_net_paid > 0 THEN s.total_discount_amount / s.total_net_paid ELSE NULL END AS discount_rate
    FROM sales_data s
    LEFT JOIN returns_data r
      ON s.year = r.year
     AND s.brand = r.brand
     AND s.gender = r.gender
     AND s.channel = r.channel
),
ranked AS (
    SELECT
        *,
        rank() OVER (PARTITION BY year, channel ORDER BY total_net_profit DESC) AS profit_rank
    FROM combined
    WHERE total_net_paid > 0
)
SELECT
    year,
    brand,
    gender,
    channel,
    total_net_paid,
    total_net_profit,
    total_quantity,
    total_discount_amount,
    distinct_orders,
    distinct_customers,
    total_return_amount,
    total_return_quantity,
    total_net_loss,
    return_rate,
    discount_rate,
    profit_rank
FROM ranked
WHERE profit_rank <= 10
ORDER BY year, channel, profit_rank
