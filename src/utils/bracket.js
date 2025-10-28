/**
 * Generate bracket structure for various formats.
 * Returns { rounds: [{ round, matches: [{id, team1, team2, court: null, winner: null, status: "pending"}]}] }
 */

export function generateBracket({ format, teams }) {
  if (format === "single") return generateSingleElim(teams);
  if (format === "double") return generateDoubleElimSimplified(teams);
  if (format === "round_robin") return generateRoundRobin(teams);
  if (format === "seeding") return generateSeedingThenMain(teams);
  return { rounds: [] };
}

function generateSingleElim(teams) {
  const teamNames = teams.slice();
  const numTeams = nextPowerOfTwo(teamNames.length);
  while (teamNames.length < numTeams) teamNames.push(null); // byes
  let matches = [];
  for (let i = 0; i < teamNames.length; i += 2) {
    matches.push({
      id: i / 2 + 1,
      team1: teamNames[i],
      team2: teamNames[i + 1],
      court: null,
      winner: null,
      status: "pending",
      score: null
    });
  }
  const rounds = [];
  let roundIndex = 1;
  rounds.push({ round: roundIndex++, matches });
  let prevRound = matches;
  while (prevRound.length > 1) {
    const nextRoundMatches = [];
    for (let i = 0; i < prevRound.length; i += 2) {
      nextRoundMatches.push({
        id: rounds.reduce((acc, r) => acc + r.matches.length, 0) + nextRoundMatches.length + 1,
        team1: null,
        team2: null,
        court: null,
        winner: null,
        status: "pending",
        score: null
      });
    }
    rounds.push({ round: roundIndex++, matches: nextRoundMatches });
    prevRound = nextRoundMatches;
  }
  return { rounds };
}

function generateRoundRobin(teams) {
  const validTeams = teams.filter(Boolean);
  const rounds = [];
  const pairings = [];
  for (let i = 0; i < validTeams.length; i++) {
    for (let j = i + 1; j < validTeams.length; j++) {
      pairings.push([validTeams[i], validTeams[j]]);
    }
  }
  let id = 1;
  // Batch pairings into rounds with up to N matches per round
  const perRound = Math.ceil(validTeams.length / 2);
  for (let i = 0; i < pairings.length; i += perRound) {
    const batch = pairings.slice(i, i + perRound).map(([a, b]) => ({
      id: id++,
      team1: a,
      team2: b,
      court: null,
      winner: null,
      status: "pending",
      score: null
    }));
    rounds.push({ round: rounds.length + 1, matches: batch });
  }
  return { rounds };
}

function generateDoubleElimSimplified(teams) {
  // Simplified: generate single elim and track losses count per team externally
  return generateSingleElim(teams);
}

function generateSeedingThenMain(teams) {
  // Simple approach: seed teams by provided order into single elim
  return generateSingleElim(teams);
}

export function advanceWinner(bracket, matchId, winnerName) {
  // Find match and set winner, then propagate to next round
  const rounds = bracket.rounds.map((r) => ({
    ...r,
    matches: r.matches.map((m) => ({ ...m }))
  }));
  let targetRoundIndex = -1;
  let idxInRound = -1;
  for (let r = 0; r < rounds.length; r++) {
    const i = rounds[r].matches.findIndex((m) => m.id === matchId);
    if (i !== -1) {
      targetRoundIndex = r;
      idxInRound = i;
      break;
    }
  }
  if (targetRoundIndex === -1) return { rounds }; // not found

  const match = rounds[targetRoundIndex].matches[idxInRound];
  match.winner = winnerName;
  match.status = "done";
  // Determine next round slot
  if (targetRoundIndex < rounds.length - 1) {
    const nextRound = rounds[targetRoundIndex + 1];
    const nextIdx = Math.floor(idxInRound / 2);
    const nextMatch = nextRound.matches[nextIdx];
    if (idxInRound % 2 === 0) {
      nextMatch.team1 = winnerName;
    } else {
      nextMatch.team2 = winnerName;
    }
  }
  return { rounds };
}

export function assignMatchToCourt(bracket, matchId, courtName) {
  const rounds = bracket.rounds.map((r) => ({
    ...r,
    matches: r.matches.map((m) => ({ ...m }))
  }));
  for (const round of rounds) {
    for (const match of round.matches) {
      if (match.id === matchId) {
        match.court = courtName;
        match.status = "in_play";
      }
    }
  }
  return { rounds };
}

export function endMatch(bracket, matchId, score, winnerName) {
  const rounds = bracket.rounds.map((r) => ({
    ...r,
    matches: r.matches.map((m) => ({ ...m }))
  }));
  for (const round of rounds) {
    for (const match of round.matches) {
      if (match.id === matchId) {
        match.score = score;
        match.winner = winnerName;
        match.status = "done";
        match.court = null;
      }
    }
  }
  return { rounds };
}

function nextPowerOfTwo(n) {
  let p = 1;
  while (p < n) p <<= 1;
  return p;
}
