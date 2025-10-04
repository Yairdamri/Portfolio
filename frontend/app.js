(() => {
  const $ = (sel) => document.querySelector(sel);

  const btnHealth = $('#btn-health');
  const btnDbPing = $('#btn-dbping');
  const btnExercises = $('#btn-exercises');
  const btnCreate = $('#btn-create');
  const btnGet = $('#btn-get');

  const healthStatus = $('#health-status');
  const dbStatus = $('#db-status');
  const exercisesOut = $('#exercises-output');
  const createOut = $('#create-output');
  const planOut = $('#plan-output');

  const inpDays = $('#inp-days');
  const inpWeeks = $('#inp-weeks');
  const inpPlanId = $('#inp-plan-id');

  function setStatus(el, ok, msg) {
    el.textContent = msg;
    el.classList.toggle('ok', ok);
    el.classList.toggle('err', !ok);
  }

  async function getJSON(path, options) {
    const res = await fetch(path, options);
    const text = await res.text();
    let data = null;
    try { data = text ? JSON.parse(text) : null; } catch {}
    if (!res.ok) throw new Error(data?.error?.message || data?.detail || res.statusText);
    return data;
  }

  btnHealth?.addEventListener('click', async () => {
    setStatus(healthStatus, true, '…');
    try {
      const data = await getJSON('/health');
      setStatus(healthStatus, true, `OK (${data.status})`);
    } catch (e) {
      setStatus(healthStatus, false, `ERR: ${e.message}`);
    }
  });

  btnDbPing?.addEventListener('click', async () => {
    setStatus(dbStatus, true, '…');
    try {
      const data = await getJSON('/v1/db/ping');
      setStatus(dbStatus, true, `OK (db=${data.db})`);
    } catch (e) {
      setStatus(dbStatus, false, `ERR: ${e.message}`);
    }
  });

  btnExercises?.addEventListener('click', async () => {
    exercisesOut.textContent = 'Loading…';
    try {
      const data = await getJSON('/v1/exercises');
      exercisesOut.textContent = JSON.stringify(data, null, 2);
    } catch (e) {
      exercisesOut.textContent = `Error: ${e.message}`;
    }
  });

  btnCreate?.addEventListener('click', async () => {
    createOut.textContent = 'Creating…';
    const body = {
      days_per_week: Number(inpDays.value || 3),
      weeks: Number(inpWeeks.value || 1),
    };
    try {
      const data = await getJSON('/v1/plans', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(body),
      });
      createOut.textContent = JSON.stringify(data, null, 2);
      if (data?.id) {
        inpPlanId.value = data.id;
      }
    } catch (e) {
      createOut.textContent = `Error: ${e.message}`;
    }
  });

  btnGet?.addEventListener('click', async () => {
    const id = inpPlanId.value.trim();
    if (!id) {
      planOut.textContent = 'Enter a Plan ID';
      return;
    }
    planOut.textContent = 'Fetching…';
    try {
      const data = await getJSON(`/v1/plans/${encodeURIComponent(id)}`);
      planOut.textContent = JSON.stringify(data, null, 2);
    } catch (e) {
      planOut.textContent = `Error: ${e.message}`;
    }
  });
})();
