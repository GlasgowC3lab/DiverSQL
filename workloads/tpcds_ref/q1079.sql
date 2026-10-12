select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 988 and 988+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'green' or i_color = 'slate') and 
        (i_units = 'Gross' or i_units = 'Case') and
        (i_size = 'extra large' or i_size = 'petite')
        ) or
        (i_category = 'Women' and
        (i_color = 'blue' or i_color = 'ghost') and
        (i_units = 'Lb' or i_units = 'Oz') and
        (i_size = 'N/A' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'steel' or i_color = 'lace') and
        (i_units = 'Carton' or i_units = 'Dram') and
        (i_size = 'medium' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'chiffon' or i_color = 'bisque') and
        (i_units = 'Bundle' or i_units = 'Unknown') and
        (i_size = 'extra large' or i_size = 'petite')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'blanched' or i_color = 'peach') and 
        (i_units = 'Ounce' or i_units = 'Pallet') and
        (i_size = 'extra large' or i_size = 'petite')
        ) or
        (i_category = 'Women' and
        (i_color = 'purple' or i_color = 'magenta') and
        (i_units = 'Bunch' or i_units = 'Each') and
        (i_size = 'N/A' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'hot' or i_color = 'sky') and
        (i_units = 'Gram' or i_units = 'Pound') and
        (i_size = 'medium' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'grey' or i_color = 'salmon') and
        (i_units = 'Tsp' or i_units = 'N/A') and
        (i_size = 'extra large' or i_size = 'petite')
        )))) > 0
 order by i_product_name
 limit 100
