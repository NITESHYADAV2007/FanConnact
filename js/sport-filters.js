(function () {
  'use strict';

  function initSportFilters() {
    var tournamentContainer = document.querySelector('[data-purpose="tournament-filters"]');
    var statusContainer = document.querySelector('[data-purpose="status-filters"]');
    var matchesContainer = document.querySelector('[data-purpose="matches-list"]');

    var activeTournament = 'All';
    var activeStatus = 'All';

    function filterMatches() {
      if (!matchesContainer) return;
      var cards = matchesContainer.querySelectorAll('[data-tournament]');
      var anyVisible = false;
      cards.forEach(function (card) {
        var sport = (card.getAttribute('data-sport') || '').toLowerCase();
        var tournament = (card.getAttribute('data-tournament') || '').toLowerCase();
        var tMatch = activeTournament === 'All' ||
          tournament === activeTournament.toLowerCase() ||
          sport === activeTournament.toLowerCase();
        var sMatch = activeStatus === 'All' || card.getAttribute('data-status') === activeStatus;
        var show = tMatch && sMatch;
        card.style.display = show ? '' : 'none';
        if (show) anyVisible = true;
      });

      var emptyMsg = matchesContainer.querySelector('.no-matches-msg');
      if (!anyVisible && cards.length > 0) {
        if (!emptyMsg) {
          emptyMsg = document.createElement('div');
          emptyMsg.className = 'no-matches-msg';
          emptyMsg.style.cssText = 'text-align:center;padding:60px 20px;color:#94a3b8;font-size:14px';
          emptyMsg.textContent = 'No matches found for selected filters.';
          matchesContainer.appendChild(emptyMsg);
        }
        emptyMsg.style.display = '';
      } else if (emptyMsg) {
        emptyMsg.style.display = 'none';
      }

      updateCountLabels();
    }

    function updateCountLabels() {
      if (!matchesContainer || !statusContainer) return;
      var cards = matchesContainer.querySelectorAll('[data-tournament]');
      var btns = statusContainer.querySelectorAll('button');
      btns.forEach(function (btn) {
        var status = btn.getAttribute('data-status') || '';
        if (!status) {
          var text = btn.textContent.trim().toLowerCase();
          if (text.indexOf('live') !== -1) status = 'live';
          else if (text.indexOf('upcoming') !== -1) status = 'upcoming';
          else if (text.indexOf('finished') !== -1) status = 'finished';
        }
        var count = 0;
        cards.forEach(function (c) {
          var tMatch = activeTournament === 'All' || c.getAttribute('data-tournament') === activeTournament;
          var sMatch = status === 'All' || status === '' || c.getAttribute('data-status') === status;
          if (tMatch && sMatch) count++;
        });
        var countSpan = btn.querySelector('[data-count]');
        if (countSpan) {
          countSpan.textContent = count;
        } else {
          var span = btn.querySelector('span:last-child');
          if (span) {
            var label = (btn.textContent || '').replace(/\(\d+\)/g, '').trim();
            span.innerHTML = label.charAt(0).toUpperCase() + label.slice(1) + ' (<span data-count="' + status + '">' + count + '</span>)';
          }
        }
      });
    }

    function watchForCards() {
      if (!matchesContainer) return;
      var check = function () {
        if (matchesContainer.querySelectorAll('[data-tournament]').length > 0) {
          updateCountLabels();
          return true;
        }
        return false;
      };
      if (!check()) {
        var obs = new MutationObserver(function () {
          if (check()) obs.disconnect();
        });
        obs.observe(matchesContainer, { childList: true, subtree: true });
        setTimeout(function () { obs.disconnect(); }, 8000);
      }
    }

    function setActiveTab(btn) {
      var parent = btn.parentElement;
      var items = parent.querySelectorAll('button');
      items.forEach(function (item) {
        item.classList.remove('text-emerald-accent', 'border-emerald-accent', 'border-b-2');
        var inactive = ['text-slate-500', 'dark:text-gray-300', 'text-gray-400', 'hover:text-white'];
        inactive.forEach(function (c) { item.classList.add(c); });
      });
      btn.classList.remove('text-slate-500', 'dark:text-gray-300', 'text-gray-400');
      btn.classList.add('text-emerald-accent', 'border-emerald-accent', 'border-b-2');
    }

    function setActiveStatus(btn) {
      var parent = btn.parentElement;
      var items = parent.querySelectorAll('button');
      items.forEach(function (item) {
        item.classList.remove('bg-brand-dark', 'border', 'border-accent-green', 'text-accent-green', 'bg-white', 'shadow-lg', 'shadow-emerald-500/20');
        item.classList.add('text-gray-400', 'hover:text-white');
        styleDarkBg(item);
      });
      btn.classList.remove('text-gray-400', 'hover:text-white');
      btn.classList.add('bg-brand-dark', 'border', 'border-accent-green', 'text-accent-green');
      styleDarkBg(btn, true);
      var dot = btn.querySelector('.bg-red-500, .bg-accent-green');
      if (dot) dot.classList.add('animate-pulse');
    }

    function styleDarkBg(el, active) {
      if (active) {
        el.style.backgroundColor = '';
        el.style.borderColor = '';
      } else {
        el.classList.add('bg-white', 'dark:bg-[#1a1a1a]');
        el.classList.remove('bg-brand-dark');
      }
    }

    if (tournamentContainer) {
      var tabs = tournamentContainer.querySelectorAll('button');
      tabs.forEach(function (btn) {
        btn.addEventListener('click', function () {
          var text = btn.textContent.trim();
          if (text === 'Stats') return;
          activeTournament = text;
          setActiveTab(btn);
          filterMatches();
        });
      });
    }

    if (statusContainer) {
      var btns = statusContainer.querySelectorAll('button');
      btns.forEach(function (btn) {
        btn.addEventListener('click', function () {
          var text = btn.textContent.trim().toLowerCase();
          if (text.indexOf('live') !== -1) activeStatus = 'live';
          else if (text.indexOf('upcoming') !== -1) activeStatus = 'upcoming';
          else if (text.indexOf('finished') !== -1) activeStatus = 'finished';
          else activeStatus = 'All';
          setActiveStatus(btn);
          filterMatches();
        });
      });
    }

    filterMatches();
    watchForCards();
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', initSportFilters);
  } else {
    initSportFilters();
  }
})();
