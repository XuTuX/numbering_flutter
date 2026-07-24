-- Remove division from Numbering and keep server validation aligned with the app.

-- LEVEL_RULE_VALUES_START
-- Generated from lib/game/numbering/level_catalog.dart. Do not edit by hand.
insert into private.numbering_level_rules (
  level_id, digit_string, available_operators,
  minimum_score, target_score, difficulty
)
values
  (1, '9243', array['+', '-']::text[], 5, 7, 1),
  (2, '2662', array['+', '-']::text[], 6, 8, 1),
  (3, '5647', array['+', '-']::text[], 9, 11, 1),
  (4, '9348', array['+', '-']::text[], 9, 12, 1),
  (5, '9568', array['+', '-']::text[], 11, 14, 1),
  (6, '22347', array['+', '-']::text[], 1, 2, 1),
  (7, '6455', array['+', '-']::text[], 8, 10, 1),
  (8, '4893', array['+', '-']::text[], 9, 12, 1),
  (9, '3663', array['+', '-']::text[], 7, 9, 1),
  (10, '5775', array['+', '-']::text[], 9, 12, 1),
  (11, '19217', array['+', '-']::text[], 8, 10, 1),
  (12, '93462', array['+', '-']::text[], 9, 12, 1),
  (13, '18821', array['+', '-']::text[], 7, 9, 1),
  (14, '84183', array['+', '-']::text[], 9, 12, 1),
  (15, '21511', array['+', '-']::text[], 1, 3, 1),
  (16, '15765', array['+', '-']::text[], 4, 6, 1),
  (17, '12388', array['+', '-']::text[], 1, 3, 1),
  (18, '12111', array['+', '-']::text[], 1, 3, 1),
  (19, '22185', array['+', '-']::text[], 2, 4, 1),
  (20, '26332', array['+', '-']::text[], 6, 8, 1),
  (21, '29254', array['+', '-', '×']::text[], 9, 11, 2),
  (22, '22348', array['+', '-', '×']::text[], 6, 8, 2),
  (23, '82375', array['+', '-', '×']::text[], 12, 16, 2),
  (24, '28559', array['+', '-', '×']::text[], 12, 16, 2),
  (25, '72217', array['+', '-', '×']::text[], 11, 14, 2),
  (26, '13652', array['+', '-', '×']::text[], 1, 3, 2),
  (27, '12112', array['+', '-', '×']::text[], 1, 3, 2),
  (28, '35546', array['+', '-', '×']::text[], 12, 15, 2),
  (29, '82197', array['+', '-', '×']::text[], 12, 16, 2),
  (30, '52143', array['+', '-', '×']::text[], 5, 7, 2),
  (31, '1012347', array['+', '-', '×']::text[], 5, 7, 2),
  (32, '345372', array['+', '-', '×']::text[], 18, 23, 2),
  (33, '657437', array['+', '-', '×']::text[], 5, 7, 2),
  (34, '324612', array['+', '-', '×']::text[], 2, 4, 2),
  (35, '465667', array['+', '-', '×']::text[], 15, 19, 2),
  (36, '921333', array['+', '-', '×']::text[], 21, 27, 2),
  (37, '879243', array['+', '-', '×']::text[], 7, 9, 2),
  (38, '326312', array['+', '-', '×']::text[], 4, 6, 2),
  (39, '762285', array['+', '-', '×']::text[], 20, 26, 2),
  (40, '132124', array['+', '-', '×']::text[], 4, 6, 2),
  (41, '10012349', array['+', '-', '×']::text[], 6, 8, 3),
  (42, '416137', array['+', '-', '×']::text[], 7, 10, 3),
  (43, '939386', array['+', '-', '×']::text[], 12, 18, 3),
  (44, '217659', array['+', '-', '×']::text[], 14, 21, 3),
  (45, '122422', array['+', '-', '×']::text[], 2, 4, 3),
  (46, '352511', array['+', '-', '×']::text[], 7, 10, 3),
  (47, '285486', array['+', '-', '×']::text[], 18, 26, 3),
  (48, '155532', array['+', '-', '×']::text[], 17, 25, 3),
  (49, '356796', array['+', '-', '×']::text[], 14, 21, 3),
  (50, '313311', array['+', '-', '×']::text[], 4, 6, 3),
  (51, '234144', array['+', '-', '×']::text[], 14, 20, 3),
  (52, '219444', array['+', '-', '×']::text[], 14, 20, 3),
  (53, '494453', array['+', '-', '×']::text[], 12, 17, 3),
  (54, '133219', array['+', '-', '×']::text[], 6, 9, 3),
  (55, '563193', array['+', '-', '×']::text[], 18, 27, 3),
  (56, '224622', array['+', '-', '×']::text[], 11, 16, 3),
  (57, '361173', array['+', '-', '×']::text[], 14, 21, 3),
  (58, '924715', array['+', '-', '×']::text[], 1, 3, 3),
  (59, '172581', array['+', '-', '×']::text[], 10, 14, 3),
  (60, '512314', array['+', '-', '×']::text[], 5, 7, 3),
  (61, '3263127', array['+', '-', '×']::text[], 5, 7, 3),
  (62, '3757743', array['+', '-', '×']::text[], 18, 26, 3),
  (63, '7433112', array['+', '-', '×']::text[], 4, 6, 3),
  (64, '1721987', array['+', '-', '×']::text[], 10, 14, 3),
  (65, '5326647', array['+', '-', '×']::text[], 17, 25, 3),
  (66, '8111891', array['+', '-', '×']::text[], 11, 16, 3),
  (67, '1399872', array['+', '-', '×']::text[], 18, 27, 3),
  (68, '6536521', array['+', '-', '×']::text[], 1, 3, 3),
  (69, '5622555', array['+', '-', '×']::text[], 15, 22, 3),
  (70, '8321382', array['+', '-', '×']::text[], 15, 22, 3),
  (71, '7412711', array['+', '-', '×']::text[], 8, 12, 3),
  (72, '4921895', array['+', '-', '×']::text[], 15, 22, 3),
  (73, '2334512', array['+', '-', '×']::text[], 12, 18, 3),
  (74, '5158337', array['+', '-', '×']::text[], 7, 10, 3),
  (75, '9294972', array['+', '-', '×']::text[], 18, 27, 3),
  (76, '1921115', array['+', '-', '×']::text[], 5, 7, 3),
  (77, '1138528', array['+', '-', '×']::text[], 1, 3, 3),
  (78, '7521354', array['+', '-', '×']::text[], 2, 4, 3),
  (79, '1192189', array['+', '-', '×']::text[], 12, 18, 3),
  (80, '2249415', array['+', '-', '×']::text[], 6, 8, 3),
  (81, '238', array['+', '-', '^', '×']::text[], 6, 8, 4),
  (82, '6523222', array['+', '-', '^', '×']::text[], 15, 22, 4),
  (83, '2597394', array['+', '-', '^', '×']::text[], 16, 23, 4),
  (84, '1323541', array['+', '-', '^', '×']::text[], 6, 9, 4),
  (85, '6113213', array['+', '-', '^', '×']::text[], 6, 8, 4),
  (86, '2569842', array['+', '-', '^', '×']::text[], 18, 26, 4),
  (87, '2136512', array['+', '-', '^', '×']::text[], 18, 27, 4),
  (88, '4442872', array['+', '-', '^', '×']::text[], 2, 4, 4),
  (89, '3711224', array['+', '-', '^', '×']::text[], 12, 18, 4),
  (90, '9728713', array['+', '-', '^', '×']::text[], 2, 4, 4),
  (91, '8494127', array['+', '-', '^', '×']::text[], 16, 23, 4),
  (92, '1221312', array['+', '-', '^', '×']::text[], 2, 4, 4),
  (93, '2142652', array['+', '-', '^', '×']::text[], 2, 4, 4),
  (94, '4581528', array['+', '-', '^', '×']::text[], 12, 17, 4),
  (95, '2133252', array['+', '-', '^', '×']::text[], 6, 8, 4),
  (96, '3211312', array['+', '-', '^', '×']::text[], 18, 27, 4),
  (97, '5211334', array['+', '-', '^', '×']::text[], 16, 24, 4),
  (98, '4361222', array['+', '-', '^', '×']::text[], 4, 6, 4),
  (99, '1181222', array['+', '-', '^', '×']::text[], 11, 16, 4),
  (100, '1527223', array['+', '-', '^', '×']::text[], 17, 25, 4),
  (101, '62175531', array['+', '-', '^', '×']::text[], 20, 29, 4),
  (102, '32171385', array['+', '-', '^', '×']::text[], 11, 16, 4),
  (103, '29321663', array['+', '-', '^', '×']::text[], 6, 9, 4),
  (104, '56483211', array['+', '-', '^', '×']::text[], 12, 18, 4),
  (105, '51535354', array['+', '-', '^', '×']::text[], 17, 25, 4),
  (106, '32248222', array['+', '-', '^', '×']::text[], 11, 16, 4),
  (107, '54565122', array['+', '-', '^', '×']::text[], 14, 20, 4),
  (108, '18524224', array['+', '-', '^', '×']::text[], 12, 18, 4),
  (109, '76712412', array['+', '-', '^', '×']::text[], 23, 34, 4),
  (110, '28642253', array['+', '-', '^', '×']::text[], 6, 8, 4),
  (111, '84863232', array['+', '-', '^', '×']::text[], 16, 24, 4),
  (112, '31371412', array['+', '-', '^', '×']::text[], 17, 25, 4),
  (113, '31225762', array['+', '-', '^', '×']::text[], 17, 25, 4),
  (114, '62729893', array['+', '-', '^', '×']::text[], 18, 27, 4),
  (115, '21118212', array['+', '-', '^', '×']::text[], 2, 4, 4),
  (116, '18325558', array['+', '-', '^', '×']::text[], 17, 25, 4),
  (117, '26215623', array['+', '-', '^', '×']::text[], 15, 22, 4),
  (118, '33742229', array['+', '-', '^', '×']::text[], 16, 24, 4),
  (119, '31239653', array['+', '-', '^', '×']::text[], 18, 27, 4),
  (120, '53234234', array['+', '-', '^', '×']::text[], 16, 23, 4),
  (121, '100012349', array['+', '-', '^', '×']::text[], 6, 8, 5),
  (122, '15356272', array['+', '-', '^', '×']::text[], 7, 10, 5),
  (123, '12262732', array['+', '-', '^', '×']::text[], 16, 24, 5),
  (124, '35284136', array['+', '-', '^', '×']::text[], 15, 22, 5),
  (125, '65481989', array['+', '-', '^', '×']::text[], 12, 18, 5),
  (126, '16981279', array['+', '-', '^', '×']::text[], 16, 23, 5),
  (127, '32261134', array['+', '-', '^', '×']::text[], 16, 24, 5),
  (128, '73137212', array['+', '-', '^', '×']::text[], 17, 25, 5),
  (129, '72974733', array['+', '-', '^', '×']::text[], 20, 30, 5),
  (130, '76523217', array['+', '-', '^', '×']::text[], 5, 7, 5),
  (131, '31931293', array['+', '-', '^', '×']::text[], 22, 33, 5),
  (132, '11533755', array['+', '-', '^', '×']::text[], 9, 13, 5),
  (133, '12139182', array['+', '-', '^', '×']::text[], 1, 3, 5),
  (134, '53673922', array['+', '-', '^', '×']::text[], 19, 28, 5),
  (135, '21134218', array['+', '-', '^', '×']::text[], 6, 9, 5),
  (136, '13274589', array['+', '-', '^', '×']::text[], 24, 35, 5),
  (137, '25652619', array['+', '-', '^', '×']::text[], 14, 21, 5),
  (138, '74135472', array['+', '-', '^', '×']::text[], 18, 27, 5),
  (139, '32137519', array['+', '-', '^', '×']::text[], 1, 3, 5),
  (140, '64726459', array['+', '-', '^', '×']::text[], 7, 10, 5),
  (141, '511112358', array['+', '-', '^', '×']::text[], 7, 10, 5),
  (142, '563214845', array['+', '-', '^', '×']::text[], 21, 31, 5),
  (143, '754463132', array['+', '-', '^', '×']::text[], 18, 27, 5),
  (144, '127341651', array['+', '-', '^', '×']::text[], 12, 17, 5),
  (145, '126743241', array['+', '-', '^', '×']::text[], 3, 5, 5),
  (146, '352294212', array['+', '-', '^', '×']::text[], 23, 34, 5),
  (147, '141113132', array['+', '-', '^', '×']::text[], 17, 25, 5),
  (148, '434275266', array['+', '-', '^', '×']::text[], 6, 8, 5),
  (149, '381277844', array['+', '-', '^', '×']::text[], 22, 33, 5),
  (150, '743441124', array['+', '-', '^', '×']::text[], 11, 16, 5),
  (151, '289957266', array['+', '-', '^', '×']::text[], 17, 25, 5),
  (152, '154592922', array['+', '-', '^', '×']::text[], 3, 5, 5),
  (153, '111682769', array['+', '-', '^', '×']::text[], 6, 8, 5),
  (154, '437461219', array['+', '-', '^', '×']::text[], 19, 28, 5),
  (155, '387214211', array['+', '-', '^', '×']::text[], 6, 9, 5),
  (156, '912198321', array['+', '-', '^', '×']::text[], 18, 27, 5),
  (157, '733245189', array['+', '-', '^', '×']::text[], 1, 3, 5),
  (158, '712211538', array['+', '-', '^', '×']::text[], 5, 7, 5),
  (159, '411729854', array['+', '-', '^', '×']::text[], 19, 28, 5),
  (160, '784731676', array['+', '-', '^', '×']::text[], 14, 21, 5),
  (161, '295359255', array['+', '-', '^', '×']::text[], 22, 33, 5),
  (162, '121429253', array['+', '-', '^', '×']::text[], 2, 4, 5),
  (163, '598225616', array['+', '-', '^', '×']::text[], 17, 25, 5),
  (164, '841211542', array['+', '-', '^', '×']::text[], 12, 18, 5),
  (165, '861295374', array['+', '-', '^', '×']::text[], 8, 11, 5),
  (166, '165539422', array['+', '-', '^', '×']::text[], 4, 6, 5),
  (167, '211521872', array['+', '-', '^', '×']::text[], 6, 9, 5),
  (168, '257786163', array['+', '-', '^', '×']::text[], 21, 31, 5),
  (169, '387681513', array['+', '-', '^', '×']::text[], 14, 21, 5),
  (170, '311585217', array['+', '-', '^', '×']::text[], 24, 35, 5),
  (171, '473811494', array['+', '-', '^', '×']::text[], 17, 25, 5),
  (172, '278442323', array['+', '-', '^', '×']::text[], 6, 8, 5),
  (173, '541312234', array['+', '-', '^', '×']::text[], 1, 3, 5),
  (174, '275521479', array['+', '-', '^', '×']::text[], 2, 4, 5),
  (175, '471323612', array['+', '-', '^', '×']::text[], 22, 33, 5),
  (176, '111521775', array['+', '-', '^', '×']::text[], 5, 7, 5),
  (177, '127698232', array['+', '-', '^', '×']::text[], 1, 3, 5),
  (178, '576257358', array['+', '-', '^', '×']::text[], 17, 25, 5),
  (179, '516115475', array['+', '-', '^', '×']::text[], 24, 35, 5),
  (180, '157239892', array['+', '-', '^', '×']::text[], 22, 33, 5),
  (181, '314276198', array['+', '-', '^', '×']::text[], 22, 32, 5),
  (182, '656821826', array['+', '-', '^', '×']::text[], 11, 16, 5),
  (183, '814551413', array['+', '-', '^', '×']::text[], 24, 35, 5),
  (184, '352715643', array['+', '-', '^', '×']::text[], 20, 29, 5),
  (185, '515733425', array['+', '-', '^', '×']::text[], 5, 7, 5),
  (186, '674744749', array['+', '-', '^', '×']::text[], 21, 31, 5),
  (187, '392112342', array['+', '-', '^', '×']::text[], 18, 26, 5),
  (188, '117387712', array['+', '-', '^', '×']::text[], 14, 21, 5),
  (189, '765287515', array['+', '-', '^', '×']::text[], 7, 10, 5),
  (190, '212412214', array['+', '-', '^', '×']::text[], 6, 8, 5),
  (191, '877223727', array['+', '-', '^', '×']::text[], 10, 14, 5),
  (192, '561132444', array['+', '-', '^', '×']::text[], 9, 13, 5),
  (193, '382421221', array['+', '-', '^', '×']::text[], 3, 5, 5),
  (194, '651821962', array['+', '-', '^', '×']::text[], 6, 9, 5),
  (195, '585238422', array['+', '-', '^', '×']::text[], 11, 16, 5),
  (196, '355175329', array['+', '-', '^', '×']::text[], 14, 21, 5),
  (197, '572671423', array['+', '-', '^', '×']::text[], 21, 31, 5),
  (198, '616294721', array['+', '-', '^', '×']::text[], 23, 34, 5),
  (199, '761187112', array['+', '-', '^', '×']::text[], 18, 26, 5),
  (200, '198286219', array['+', '-', '^', '×']::text[], 23, 34, 5)
on conflict (level_id) do update
set digit_string = excluded.digit_string,
    available_operators = excluded.available_operators,
    minimum_score = excluded.minimum_score,
    target_score = excluded.target_score,
    difficulty = excluded.difficulty,
    updated_at = now();
-- LEVEL_RULE_VALUES_END

create or replace function public._numbering_precedence(p_operator text)
returns integer
language sql
immutable
strict
set search_path = public
as $$
  select case
    when p_operator = '^' then 3
    when p_operator = '×' then 2
    else 1
  end;
$$;

create or replace function public._numbering_apply_operator(
  p_left bigint,
  p_operator text,
  p_right bigint
)
returns bigint
language plpgsql
immutable
strict
set search_path = public
as $$
declare
  v_result bigint;
  v_factor bigint;
  v_exponent bigint;
begin
  case p_operator
    when '+' then v_result := p_left + p_right;
    when '-' then v_result := p_left - p_right;
    when '×' then v_result := p_left * p_right;
    when '^' then
      if p_right < 0 then
        raise exception 'invalid expression: exponent must be non-negative';
      end if;
      if p_left = 0 and p_right = 0 then
        raise exception 'invalid expression: zero to zero power';
      end if;
      v_result := 1;
      v_factor := p_left;
      v_exponent := p_right;
      while v_exponent > 0 loop
        if v_exponent % 2 = 1 then
          if v_factor <> 0
             and abs(v_result) > 999999999 / abs(v_factor) then
            raise exception 'invalid expression: result outside Numbering range';
          end if;
          v_result := v_result * v_factor;
        end if;
        v_exponent := v_exponent / 2;
        if v_exponent > 0 then
          if v_factor <> 0
             and abs(v_factor) > 999999999 / abs(v_factor) then
            raise exception 'invalid expression: result outside Numbering range';
          end if;
          v_factor := v_factor * v_factor;
        end if;
      end loop;
    else
      raise exception 'invalid expression: unknown operator';
  end case;
  if abs(v_result) > 999999999 then
    raise exception 'invalid expression: result outside Numbering range';
  end if;
  return v_result;
end;
$$;

create or replace function public._numbering_evaluate_expression(p_source text)
returns bigint
language plpgsql
immutable
strict
set search_path = public
as $$
declare
  v_values bigint[] := array[]::bigint[];
  v_operators text[] := array[]::text[];
  v_index integer := 1;
  v_length integer := char_length(p_source);
  v_character text;
  v_start integer;
  v_expects_operand boolean := true;
  v_left bigint;
  v_right bigint;
  v_operator text;
  v_count integer;
begin
  if v_length < 1 or v_length > 64
     or p_source !~ '^[0-9+\-×^()]+$' then
    raise exception 'invalid expression';
  end if;

  while v_index <= v_length loop
    v_character := substr(p_source, v_index, 1);
    if v_character ~ '^[0-9]$' then
      if not v_expects_operand then
        raise exception 'invalid expression: operator required';
      end if;
      v_start := v_index;
      while v_index <= v_length
        and substr(p_source, v_index, 1) ~ '^[0-9]$' loop
        v_index := v_index + 1;
      end loop;
      v_values := array_append(
        v_values,
        substr(p_source, v_start, v_index - v_start)::bigint
      );
      v_expects_operand := false;
      continue;
    elsif v_character = '(' then
      if not v_expects_operand then
        raise exception 'invalid expression: implicit multiplication';
      end if;
      v_operators := array_append(v_operators, v_character);
      v_index := v_index + 1;
      continue;
    elsif v_character = ')' then
      if v_expects_operand then
        raise exception 'invalid expression: empty parenthesis';
      end if;
      while coalesce(array_length(v_operators, 1), 0) > 0
        and v_operators[array_length(v_operators, 1)] <> '(' loop
        v_count := array_length(v_values, 1);
        if v_count < 2 then
          raise exception 'invalid expression: missing operand';
        end if;
        v_right := v_values[v_count];
        v_left := v_values[v_count - 1];
        v_values := coalesce(v_values[1:v_count - 2], array[]::bigint[]);
        v_count := array_length(v_operators, 1);
        v_operator := v_operators[v_count];
        v_operators := coalesce(v_operators[1:v_count - 1], array[]::text[]);
        v_values := array_append(
          v_values,
          public._numbering_apply_operator(v_left, v_operator, v_right)
        );
      end loop;
      v_count := coalesce(array_length(v_operators, 1), 0);
      if v_count = 0 then
        raise exception 'invalid expression: unmatched parenthesis';
      end if;
      v_operators := coalesce(v_operators[1:v_count - 1], array[]::text[]);
      v_expects_operand := false;
      v_index := v_index + 1;
      continue;
    elsif v_character in ('+', '-', '×', '^') then
      if v_expects_operand then
        raise exception 'invalid expression: unary operator';
      end if;
      while coalesce(array_length(v_operators, 1), 0) > 0
        and v_operators[array_length(v_operators, 1)] <> '('
        and (
          public._numbering_precedence(
            v_operators[array_length(v_operators, 1)]
          ) > public._numbering_precedence(v_character)
          or (
            public._numbering_precedence(
              v_operators[array_length(v_operators, 1)]
            ) = public._numbering_precedence(v_character)
            and v_character <> '^'
          )
        ) loop
        v_count := array_length(v_values, 1);
        if v_count < 2 then
          raise exception 'invalid expression: missing operand';
        end if;
        v_right := v_values[v_count];
        v_left := v_values[v_count - 1];
        v_values := coalesce(v_values[1:v_count - 2], array[]::bigint[]);
        v_count := array_length(v_operators, 1);
        v_operator := v_operators[v_count];
        v_operators := coalesce(v_operators[1:v_count - 1], array[]::text[]);
        v_values := array_append(
          v_values,
          public._numbering_apply_operator(v_left, v_operator, v_right)
        );
      end loop;
      v_operators := array_append(v_operators, v_character);
      v_expects_operand := true;
      v_index := v_index + 1;
      continue;
    end if;
    raise exception 'invalid expression';
  end loop;

  if v_expects_operand then
    raise exception 'invalid expression: trailing operator';
  end if;
  while coalesce(array_length(v_operators, 1), 0) > 0 loop
    v_count := array_length(v_operators, 1);
    v_operator := v_operators[v_count];
    if v_operator = '(' then
      raise exception 'invalid expression: unmatched parenthesis';
    end if;
    v_operators := coalesce(v_operators[1:v_count - 1], array[]::text[]);
    v_count := array_length(v_values, 1);
    if v_count < 2 then
      raise exception 'invalid expression: missing operand';
    end if;
    v_right := v_values[v_count];
    v_left := v_values[v_count - 1];
    v_values := coalesce(v_values[1:v_count - 2], array[]::bigint[]);
    v_values := array_append(
      v_values,
      public._numbering_apply_operator(v_left, v_operator, v_right)
    );
  end loop;
  if coalesce(array_length(v_values, 1), 0) <> 1 then
    raise exception 'invalid expression';
  end if;
  return v_values[1];
end;
$$;

revoke all on function public._numbering_precedence(text) from public;
revoke all on function public._numbering_apply_operator(bigint, text, bigint)
  from public;
revoke all on function public._numbering_evaluate_expression(text)
  from public;
