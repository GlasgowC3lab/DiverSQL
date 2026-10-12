WITH date_joined AS (
    SELECT
        d.d_date,
        d.d_day_name,
        d.d_week_seq,
        d.d_month_seq,
        d.d_year,
        d.d_date_sk
    FROM date_dim d
),
catalog AS (
    SELECT
        cp.cp_catalog_page_sk,
        cp.cp_department,
        cp.cp_type,
        cp.cp_start_date_sk,
        cp.cp_end_date_sk,
        cp.cp_catalog_page_number
    FROM catalog_page cp
),
inventory_agg AS (
    SELECT
        i.inv_date_sk,
        SUM(i.inv_quantity_on_hand) AS total_quantity_on_hand,
        COUNT(DISTINCT i.inv_warehouse_sk) AS warehouse_cnt
    FROM inventory i
    GROUP BY i.inv_date_sk
),
store_agg AS (
    SELECT
        s.s_closed_date_sk,
        COUNT(DISTINCT s.s_store_id) AS store_cnt,
        MAX(s.s_floor_space) AS max_floor_space,
        MIN(s.s_floor_space) AS min_floor_space
    FROM store s
    GROUP BY s.s_closed_date_sk
),
returns_agg AS (
    SELECT
        wr.wr_returned_date_sk,
        SUM(wr.wr_return_amt) AS total_return_amt,
        SUM(wr.wr_return_tax) AS total_return_tax,
        SUM(wr.wr_net_loss) AS total_net_loss,
        COUNT(*) AS return_cnt
    FROM web_returns wr
    GROUP BY wr.wr_returned_date_sk
)
SELECT
    d.d_date,
    d.d_day_name,
    c.cp_department,
    c.cp_type,
    iag.total_quantity_on_hand,
    iag.warehouse_cnt,
    sag.store_cnt,
    sag.max_floor_space,
    rag.total_return_amt,
    rag.total_return_tax,
    rag.total_net_loss,
    rag.return_cnt,
    (rag.total_return_amt + rag.total_return_tax) AS total_return_with_tax,
    ROW_NUMBER() OVER (PARTITION BY c.cp_department ORDER BY (rag.total_return_amt + rag.total_return_tax) DESC) AS dept_return_rank
FROM date_joined d
JOIN catalog c ON c.cp_end_date_sk = d.d_date_sk
JOIN inventory_agg iag ON iag.inv_date_sk = d.d_date_sk
JOIN store_agg sag ON sag.s_closed_date_sk = d.d_date_sk
JOIN returns_agg rag ON rag.wr_returned_date_sk = d.d_date_sk
WHERE c.cp_type = 'Promotion'
ORDER BY total_return_with_tax DESC
LIMIT 100
