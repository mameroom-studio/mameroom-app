-- MAMEROOM demo import for 보험계리 개념 테스트_12.pdf
-- Purpose:
-- - Temporary UI/UX unblock while server PDF parsing is being fixed.
-- - Inserts 10 example quiz questions based on the provided PDF.
-- - Does not change schema, RPC, AI, wallet, seed, or shop logic.
--
-- How it works:
-- - Finds the latest public.study_materials row whose title is 보험계리 개념 테스트_12.pdf.
-- - Marks the material as completed.
-- - Upserts 10 concepts and 10 initial questions.
-- - Re-running this SQL is safe: it updates the same material/order_index rows.

begin;

do $$
declare
  v_material_id uuid;
  v_user_id uuid;
  v_raw_text text := '보험금융 IT 영업 교재 - 핵심 용어집 (심화 버전)

1. ALM (Asset Liability Management, 자산부채관리)
보험사는 장기 부채(보험금 지급)와 자산(채권, 주식, 대출)을 동시에 관리해야 한다. 금리와 환율 변동은 부채 가치에 큰 영향을 주기 때문에 자산 운용 전략과 연결된다. IFRS17은 부채 시가 평가를 요구하고, K-ICS는 금리 및 시장리스크를 정교화하므로 ALM 필요성이 커진다.

2. AiR (Automated intelligent Report)
감독원 보고서는 보험사별로 연간 수백 건 이상 제출되며, 엑셀과 워드 기반 작업은 인적 오류와 시간 낭비를 만든다. AiR은 금감원 보고 양식에 데이터를 자동 매핑하고 보고서를 생성하여 검사 대응 리스크를 줄인다.

3. IFRS17
2023년 전면 시행된 국제회계기준이다. 보험 부채를 원가가 아니라 시가, 즉 현재가치로 평가한다. 미래 현금흐름, 위험조정(RA), 계약서비스마진(CSM)을 계산하며 재무제표 변동성이 커져 ALM과 리스크 관리가 중요해진다.

4. K-ICS
Solvency II 기반 한국형 자본규제다. 자산과 부채 리스크를 세분화하여 평가하고 지급여력비율을 관리한다. 금리, 신용, 시장, 보험위험 등을 세분화하며 표준모델 이후 내부모델과 ORSA로 확장될 수 있다.

5. 헷징
보험사는 변액보험 보증금 등 확정 지급 의무 때문에 시장 변동 리스크를 관리해야 한다. 환헷징, 옵션, 스왑 등 파생상품을 활용하며 감독당국은 헷징 효과의 정량 보고를 요구한다.

6. ORSA / 내부모델
ORSA는 보험사가 자체적으로 리스크와 자본을 평가해 보고하는 제도다. 내부모델은 표준모델 대신 자체 구축한 리스크 평가 모델이다. 리스크 시나리오, 확률적 시뮬레이션, 스트레스 테스트와 연결된다.

7. DR
Disaster Recovery는 장애나 재해가 발생했을 때 금융기관의 서비스 연속성을 보장하는 체계다. DR 센터, 데이터 실시간 복제, 장애 시 자동 전환이 포함되며 금융보안원 규제와 모의훈련 보고와 연결된다.

8. 준비금 검증
준비금은 보험사가 향후 보험금 지급을 위해 적립하는 부채다. IFRS17 이후 계산 방식이 복잡해져 검증 중요성이 커졌고, 감독원 감사 시 검증자료 제출이 필요하다.

9. PV 검증
PV 검증은 미래 현금흐름을 할인율로 현재가치 환산하는 과정의 오류를 확인하는 작업이다. IFRS17과 K-ICS 모두 PV 기반 계산을 요구하며 회계감사 대응의 핵심이다.

10. 위험률 산출
위험률은 보험 상품 가격 산출과 준비금 계산의 기초 지표다. 사망률, 사고율, 해지율 등이 포함된다. 경험통계와 빅데이터 기반 보정은 상품 경쟁력과 리스크 관리 경쟁력을 높인다.';
begin
  select sm.id, sm.user_id
    into v_material_id, v_user_id
  from public.study_materials sm
  where sm.title = '보험계리 개념 테스트_12.pdf'
     or sm.title ilike '%보험계리 개념 테스트_12%'
  order by sm.created_at desc
  limit 1;

  if v_material_id is null then
    raise exception 'No study_materials row found for 보험계리 개념 테스트_12.pdf. Upload the PDF first, then run this import.';
  end if;

  update public.study_materials
  set
    status = 'completed',
    raw_text = coalesce(nullif(raw_text, ''), v_raw_text),
    structured_text = jsonb_build_object(
      'source', 'manual_demo_import',
      'title', '보험계리 개념 테스트_12.pdf',
      'conceptCount', 10,
      'questionCount', 10,
      'questionMix', jsonb_build_object('short_answer', 7, 'multiple_choice', 3)
    ),
    analysis_error = null,
    analysis_completed_at = now(),
    updated_at = now()
  where id = v_material_id;

  create temp table if not exists _mameroom_demo_concepts (
    order_index integer,
    name text,
    description text,
    importance integer,
    evidence_text text
  ) on commit drop;

  truncate table _mameroom_demo_concepts;

  insert into _mameroom_demo_concepts(order_index, name, description, importance, evidence_text)
  values
    (1, 'ALM', '보험사의 장기 부채와 자산을 금리 및 시장 변동과 함께 관리하는 자산부채관리 개념이다.', 5, 'IFRS17과 K-ICS 환경에서 부채 현재가치, 채권 가치, 헷징 전략을 함께 관리해야 한다.'),
    (2, 'AiR', '감독원 보고 양식에 데이터를 자동 매핑하고 보고서를 생성하는 자동 보고 솔루션이다.', 4, '보고서 자동화는 인적 오류와 검사 대응 리스크를 줄이고 연간 업무 시간을 절감한다.'),
    (3, 'IFRS17', '보험 부채를 원가가 아닌 현재가치로 평가하는 국제회계기준이다.', 5, '미래 현금흐름, 위험조정(RA), 계약서비스마진(CSM) 계산이 핵심이다.'),
    (4, 'K-ICS', 'Solvency II 기반의 한국형 보험 자본규제로 자산과 부채 리스크를 세분화해 평가한다.', 5, '금리, 신용, 시장, 보험위험 등을 세분화하고 지급여력비율을 관리한다.'),
    (5, '헷징', '시장 변동으로 인한 지급 의무 리스크를 파생상품 등으로 줄이는 리스크 관리 전략이다.', 4, '변액보험 보증금, 환율 변동, 옵션 및 스왑을 통한 리스크 완화와 연결된다.'),
    (6, 'ORSA / 내부모델', '보험사가 자체적으로 리스크와 자본을 평가하고 보고하는 제도 및 모델 체계다.', 4, '리스크 시나리오 분석, 확률적 시뮬레이션, 스트레스 테스트와 관련된다.'),
    (7, 'DR', '장애나 재해 발생 시 금융 서비스 연속성을 보장하는 재해복구 체계다.', 3, 'DR 센터, 데이터 실시간 복제, 장애 시 자동 전환과 모의훈련 보고가 포함된다.'),
    (8, '준비금 검증', '향후 보험금 지급을 위해 적립하는 부채인 준비금 계산의 타당성을 확인하는 절차다.', 4, 'IFRS17 이후 계산 방식이 복잡해져 외부 및 내부 검증의 중요성이 커졌다.'),
    (9, 'PV 검증', '미래 현금흐름을 할인율로 현재가치 환산하는 과정의 오류를 확인하는 작업이다.', 4, 'IFRS17과 K-ICS 모두 PV 기반 계산을 요구한다.'),
    (10, '위험률 산출', '보험 상품 가격과 준비금 계산의 기초가 되는 사망률, 사고율, 해지율 등을 산출하는 작업이다.', 4, '경험통계와 빅데이터 기반 보정은 상품 경쟁력과 리스크 관리 경쟁력을 높인다.');

  insert into public.concepts (
    user_id,
    material_id,
    name,
    description,
    importance,
    evidence
  )
  select
    v_user_id,
    v_material_id,
    c.name,
    c.description,
    c.importance,
    jsonb_build_object('text', c.evidence_text, 'page', ceil(c.order_index / 4.0)::integer)
  from _mameroom_demo_concepts c
  on conflict (material_id, name)
  do update set
    description = excluded.description,
    importance = excluded.importance,
    evidence = excluded.evidence;

  create temp table if not exists _mameroom_demo_questions (
    order_index integer,
    concept_name text,
    type text,
    question_text text,
    options jsonb,
    answer text,
    explanation text,
    evidence_text text,
    difficulty integer
  ) on commit drop;

  truncate table _mameroom_demo_questions;

  insert into _mameroom_demo_questions (
    order_index,
    concept_name,
    type,
    question_text,
    options,
    answer,
    explanation,
    evidence_text,
    difficulty
  )
  values
    (
      1,
      'ALM',
      'multiple_choice',
      'ALM이 보험사에서 중요한 이유로 가장 적절한 것은 무엇인가요?',
      '["장기 부채와 자산을 금리·시장 변동과 함께 관리해야 하기 때문", "단기 마케팅 비용만 계산하기 때문", "고객 상담 기록을 자동 요약하기 때문", "보험 약관 문구를 번역하기 때문"]'::jsonb,
      '장기 부채와 자산을 금리·시장 변동과 함께 관리해야 하기 때문',
      'ALM은 보험금 지급이라는 장기 부채와 자산 운용을 함께 관리하는 체계이며, IFRS17과 K-ICS 대응에도 중요합니다.',
      '보험사는 장기 부채와 자산을 동시에 관리하고 금리 변동이 부채 가치에 영향을 준다.',
      3
    ),
    (
      2,
      'AiR',
      'short_answer',
      'AiR은 감독원 보고 업무에서 어떤 문제를 줄이기 위해 도입되나요?',
      '[]'::jsonb,
      '인적 오류와 시간 낭비',
      'AiR은 엑셀·워드 기반 보고 작업의 수작업 오류와 반복 업무 시간을 줄이는 자동 보고 솔루션입니다.',
      '감독원 보고서는 대부분 엑셀·워드 기반이라 인적 오류와 시간 낭비가 발생한다.',
      2
    ),
    (
      3,
      'IFRS17',
      'multiple_choice',
      'IFRS17에서 보험 부채 평가 방식으로 맞는 설명은 무엇인가요?',
      '["원가가 아닌 현재가치로 평가한다", "보험료 수입만 기준으로 평가한다", "부채 평가는 하지 않는다", "해지율만으로 평가한다"]'::jsonb,
      '원가가 아닌 현재가치로 평가한다',
      'IFRS17은 보험 부채를 시가, 즉 현재가치 기반으로 평가하도록 요구합니다.',
      'IFRS17은 보험사 부채를 원가가 아닌 시가, 현재가치로 평가한다.',
      3
    ),
    (
      4,
      'K-ICS',
      'short_answer',
      'K-ICS가 세분화하여 평가하는 대표 리스크를 두 가지 이상 쓰세요.',
      '[]'::jsonb,
      '금리, 신용, 시장, 보험위험',
      'K-ICS는 자산과 부채 리스크를 금리, 신용, 시장, 보험위험 등으로 세분화하여 평가합니다.',
      'K-ICS는 금리, 신용, 시장, 보험위험 등 리스크를 세분화한다.',
      4
    ),
    (
      5,
      '헷징',
      'short_answer',
      '보험사가 헷징을 활용하는 주된 목적은 무엇인가요?',
      '[]'::jsonb,
      '시장 변동 리스크 관리',
      '헷징은 환율, 금리, 변액보험 보증금 등 시장 변동에 따른 지급 리스크를 줄이기 위한 전략입니다.',
      '변액보험 보증금 등 확정 지급 의무 때문에 시장 변동 리스크 관리가 필요하다.',
      3
    ),
    (
      6,
      'ORSA / 내부모델',
      'multiple_choice',
      'ORSA와 내부모델에 대한 설명으로 가장 적절한 것은 무엇인가요?',
      '["보험사가 자체적으로 리스크와 자본을 평가하는 체계", "보험 약관을 디자인하는 도구", "고객 앱의 로그인 방식", "보험금 청구 이미지를 압축하는 기능"]'::jsonb,
      '보험사가 자체적으로 리스크와 자본을 평가하는 체계',
      'ORSA는 자기위험지급여력평가이며 내부모델은 자체 리스크 평가 모델로, 시나리오 분석과 스트레스 테스트에 활용됩니다.',
      'ORSA는 보험사가 자체적으로 리스크자본을 평가해 보고하는 제도다.',
      4
    ),
    (
      7,
      'DR',
      'short_answer',
      'DR 체계가 보장하려는 핵심 가치는 무엇인가요?',
      '[]'::jsonb,
      '서비스 연속성',
      'DR은 장애나 재해가 발생해도 금융기관 서비스가 중단되지 않도록 복구 체계를 마련하는 것입니다.',
      '금융기관은 장애·재해 발생 시 반드시 서비스 연속성을 보장해야 한다.',
      2
    ),
    (
      8,
      '준비금 검증',
      'short_answer',
      '준비금 검증의 중요성이 IFRS17 이후 커진 이유는 무엇인가요?',
      '[]'::jsonb,
      '준비금 계산 방식이 복잡해졌기 때문',
      'IFRS17 이후 준비금 계산 방식이 복잡해져 외부 검증과 내부 시스템 검증의 중요성이 증가했습니다.',
      'IFRS17 이후 계산 방식이 복잡해져 검증 중요성이 증가했다.',
      3
    ),
    (
      9,
      'PV 검증',
      'short_answer',
      'PV 검증은 어떤 계산 과정의 오류를 확인하나요?',
      '[]'::jsonb,
      '미래 현금흐름을 할인율로 현재가치 환산하는 과정',
      'PV 검증은 미래 현금흐름을 현재가치로 할인하는 과정에서 발생할 수 있는 오류를 확인합니다.',
      '미래 현금흐름을 할인율로 현재가치 환산하는 과정에서 오류 가능성이 크다.',
      3
    ),
    (
      10,
      '위험률 산출',
      'short_answer',
      '위험률 산출에 포함되는 대표 지표를 세 가지 쓰세요.',
      '[]'::jsonb,
      '사망률, 사고율, 해지율',
      '위험률은 보험 상품 가격 산출과 준비금 계산의 기초이며 사망률, 사고율, 해지율 등이 포함됩니다.',
      '위험률은 사망률, 사고율, 해지율을 포함하며 상품 가격과 준비금 계산의 기초 지표다.',
      3
    );

  insert into public.questions (
    user_id,
    material_id,
    concept_id,
    section_id,
    source_hash,
    type,
    question_text,
    options,
    answer,
    explanation,
    evidence,
    difficulty,
    initial_batch,
    order_index
  )
  select
    v_user_id,
    v_material_id,
    c.id,
    null,
    'insurance-actuary-demo-v1-' || q.order_index::text,
    q.type,
    q.question_text,
    q.options,
    q.answer,
    q.explanation,
    jsonb_build_object('text', q.evidence_text, 'source', '보험계리 개념 테스트_12.pdf'),
    q.difficulty,
    true,
    q.order_index
  from _mameroom_demo_questions q
  join public.concepts c
    on c.material_id = v_material_id
   and c.user_id = v_user_id
   and c.name = q.concept_name
  on conflict (material_id, order_index)
  do update set
    concept_id = excluded.concept_id,
    source_hash = excluded.source_hash,
    type = excluded.type,
    question_text = excluded.question_text,
    options = excluded.options,
    answer = excluded.answer,
    explanation = excluded.explanation,
    evidence = excluded.evidence,
    difficulty = excluded.difficulty,
    initial_batch = excluded.initial_batch;

  raise notice 'Imported demo questions for material_id=% user_id=%', v_material_id, v_user_id;
end $$;

commit;

select
  sm.id as material_id,
  sm.title,
  sm.status,
  count(q.id) filter (where q.initial_batch) as initial_question_count
from public.study_materials sm
left join public.questions q on q.material_id = sm.id
where sm.title = '보험계리 개념 테스트_12.pdf'
   or sm.title ilike '%보험계리 개념 테스트_12%'
group by sm.id, sm.title, sm.status
order by max(sm.created_at) desc;
