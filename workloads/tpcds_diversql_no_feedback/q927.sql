WITH catalog_sub AS (
    SELECT
        cr.cr_returned_date_sk AS date_sk,
        cr.cr_return_amount AS return_amount,
        cr.cr_net_loss AS net_loss,
        r.r_reason_desc,
        ca.ca_state,
        word,
        LAG(cr.cr_return_amount) OVER (PARTITION BY ca.ca_state ORDER BY cr.cr_returned_date_sk) AS prev_return_amount
    FROM catalog_returns AS cr
    JOIN catalog_sales AS cs
        ON cr.cr_order_number = cs.cs_order_number
    JOIN reason AS r
        ON cr.cr_reason_sk = r.r_reason_sk
    JOIN customer_address AS ca
        ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    JOIN UNNEST(split(r.r_reason_desc, ' ')) AS t(word)
        ON TRUE
    WHERE cr.cr_returned_date_sk BETWEEN 2450000 AND 2451000
),
web_sub AS (
    SELECT
        wr.wr_returned_date_sk AS date_sk,
        wr.wr_return_amt AS return_amount,
        wr.wr_net_loss AS net_loss,
        r.r_reason_desc,
        ca.ca_state,
        word,
        LAG(wr.wr_return_amt) OVER (PARTITION BY ca.ca_state ORDER BY wr.wr_returned_date_sk) AS prev_return_amount
    FROM web_returns AS wr
    JOIN reason AS r
        ON wr.wr_reason_sk = r.r_reason_sk
    JOIN customer_address AS ca
        ON wr.wr_refunded_addr_sk = ca.ca_address_sk
    JOIN UNNEST(split(r.r_reason_desc, ' ')) AS t(word)
        ON TRUE
    WHERE wr.wr_returned_date_sk BETWEEN 2450000 AND 2451000
)
SELECT
    date_sk,
    return_amount,
    net_loss,
    r_reason_desc,
    ca_state,
    word,
    prev_return_amount
FROM (
    SELECT date_sk, return_amount, net_loss, r_reason_desc, ca_state, word, prev_return_amount FROM catalog_sub
    UNION ALL
    SELECT date_sk, return_amount, net_loss, r_reason_desc, ca_state, word, prev_return_amount FROM web_sub
) AS combined
ORDER BY date_sk DESC, return_amount DESC
LIMIT 100
