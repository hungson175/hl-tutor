# Curriculum: From Zero to Building with Claude Code

Target: intelligent adults with zero programming experience.
Method: learning by doing. Every lesson produces a real artifact. Concepts introduced just-in-time when the student feels the friction that the concept solves.

---

## Design Principles

1. First visible result within 5 minutes of each lesson
2. Never explain a concept before the student needs it
3. Introduce friction, then solve it — the student feels why each feature exists
4. One new Claude Code feature per lesson (after the basics)
5. Scaffolding fades: early = "type exactly this", later = "do this however you want"
6. Every lesson ends with a tangible artifact the student can show someone

---

## Phase 1: The Basics (Lessons 1-4)

### Lesson 1: The Terminal

Goal: comfortable navigating folders from the command line.
Artifact: a folder structure they created.

Steps:
1. Terminal = "text-based remote control — type commands instead of clicking."
2. "ls" — list what's here. Should see memory/, projects/, prompts/.
3. "mkdir" — create a folder, then "ls" to confirm it appeared.
4. "cd" — go into folder, "ls" (empty), "cd .." to go back.
5. Tab autocomplete — type "cd pro" + Tab. Practice this.
6. "cd ~" goes home, "cd ~/tutor-workspace" comes back.
7. Free exploration — let them wander, create folders. Give space.
8. Practice task — "Create practice/, go in, create one/ and two/, list them, come back."

Features introduced: terminal, ls, cd, mkdir, Tab autocomplete
Aha moment: Tab autocomplete — "the computer finishes my typing for me"

---

### Lesson 2: Meet Claude Code

Goal: start Claude Code, give it an instruction, run the result.
Artifact: a Python file that prints something when run.

Steps:
1. "cd projects" — where all projects live.
2. "mkdir hello-world && cd hello-world" — every project gets its own folder.
3. "claude" — starts an AI that writes code from plain language.
4. First instruction: "Create a Python file that prints hello world."
5. "/exit", then "python3 hello.py" — they see their code run.

Features introduced: claude command, /exit, running code
Aha moment: "I just told the computer what to do in Vietnamese/English and it wrote code for me"

Teaching note: reinforce the "one project = one folder" rule. This becomes critical later.

---

### Lesson 3: Build a Game

Goal: build a playable game. Teaches build > play > modify loop.
Artifact: a working tic-tac-toe game with at least one customization.

Steps:
1. New project folder: "cd ~/tutor-workspace/projects && mkdir tic-tac-toe && cd tic-tac-toe"
2. "claude"
3. "Build a tic-tac-toe game I can play in the terminal."
4. "/exit", run, play a few rounds.
5. Back to Claude Code — modify it ("5x5 board", "add colors", "add score tracking").
6. Exit, run, see changes. This is the iterate loop.

Features introduced: the iterate loop (describe > build > test > modify)
Aha moment: "I changed the game just by asking — I didn't touch any code"

Teaching note: the iterate loop is THE core pattern. Everything from here builds on it.

---

### Lesson 4: Build Your Personal Website

Goal: build a real website they can see in their browser.
Artifact: a personal website viewable in the browser.

Steps:
1. New project: "mkdir my-website && cd my-website && claude"
2. "Create a personal website for me. My name is [name]."
3. Claude Code creates the site. "/exit".
4. View the site — step by step:
   - "python3 -m http.server 8080" to start the server
   - "Open a new tab in your browser — click the + button at the top"
   - "Type this address at the top: localhost:8080"
   - "Press Enter. You should see your website!"
5. Stop server (Ctrl+C), start Claude Code again.
6. "I'm the CEO of [company]. Research me online and redesign with real info."
7. Same cycle: exit, start server, view in browser.
8. "Redesign to look professional and match my personality."
9. Reflect: start simple > add content > refine design. That's how software gets built.

Features introduced: http server, viewing web pages locally, the refine cycle
Aha moment: "I built a real website — from nothing — in 15 minutes"

Teaching note: do NOT explain localhost. Just say "type this address." Do NOT explain what a server is. Just say "this command lets your browser see the website."

---

## Phase 2: Claude Code Power Tools (Lessons 5-8)

Each lesson builds on the website project. The student keeps improving it while discovering new Claude Code features. This is intentional — a familiar project reduces cognitive load so the student can focus on the new tool.

### Lesson 5: Teaching Claude to Remember — CLAUDE.md

Goal: create a CLAUDE.md so Claude remembers their project across sessions.
Artifact: a CLAUDE.md file that makes Claude instantly understand their project.

Friction setup:
- Student exits Claude Code from their website project.
- Student starts Claude Code again with "claude".
- Tell Claude "Add a contact form to my website."
- Claude may ask basic questions it should already know (what's the project about, what's the student's name, etc.)
- Point out: "Claude forgot everything. Every new session starts from zero."

Solution:
1. "There's a way to leave a note for Claude — like a sticky note on your desk."
2. Create CLAUDE.md manually. Have student type (in Claude Code):
   "Create a file called CLAUDE.md with these lines:
   This is [name]'s personal website.
   Built with HTML/CSS.
   Run with: python3 -m http.server 8080"
3. "/exit", then "claude" again.
4. Claude now knows the project instantly. Ask it to add something — it doesn't ask basic questions anymore.
5. Show "/init" — "Claude can also write this note itself by scanning your project."
6. Run "/init" in a project and see what it generates. Compare to the manual version.

Features introduced: CLAUDE.md (project memory), /init, /memory
Aha moment: "Claude remembers between sessions now — it reads my note every time it starts"

Progressive disclosure: only teach project-level CLAUDE.md here. Don't mention global CLAUDE.md, rules/, or auto memory yet.

---

### Lesson 6: Making It Beautiful — Skills

Goal: transform the website from plain to polished using a skill.
Artifact: a dramatically improved website design.

Friction setup:
- Student's website works but looks generic/basic.
- They could describe design improvements in Claude Code, but that's a lot of typing.

Solution:
1. "There's a shortcut. Type this: /frontend-design"
2. Claude redesigns with professional styling, animations, color schemes.
3. Exit, start server, view in browser.
4. Compare before vs after — dramatic improvement.
5. Now explain: "What you just used is called a 'skill.' Someone wrote detailed design instructions. You invoked them with one command."
6. Show "/help" — "See all the shortcuts available to you."
7. Let student explore a few interesting-looking skills from the list.

Features introduced: skills (what they are, how to invoke), /help for discovery
Aha moment: "One command completely transformed my website — someone already taught Claude how to do this well"

Teaching note: if /frontend-design is not available in the tutor workspace, use another visually impactful skill or have the student write a detailed design prompt instead. The point is the before/after contrast.

---

### Lesson 7: Your First Custom Shortcut — Creating Skills

Goal: create a personal skill the student can reuse.
Artifact: a working custom skill they wrote themselves.

Friction setup:
- Student is iterating on their website and keeps typing similar instructions: "Review this page and suggest 3 improvements" or "Add Vietnamese text to this page."
- Point out the repetition: "You keep typing almost the same thing."

Solution:
1. "You can save any instruction as your own shortcut — like the design one from last lesson."
2. In Claude Code, tell it:
   "Create a file at .claude/commands/review.md with this content:
   Review the current website and suggest exactly 3 specific improvements. Be concise."
3. "/exit", then "claude" again.
4. Type "/review" — it works! Their custom shortcut.
5. Explain the pattern: any .md file in .claude/commands/ becomes a slash command.
6. Challenge: "Create another shortcut for something you do often."

Features introduced: custom commands/skills (creation), .claude/commands/ directory
Aha moment: "I just created my own tool — I automated something I was doing manually"

Teaching note: use .claude/commands/ (simpler) rather than .claude/skills/ (more features but more complex). They can graduate to skills later. The concept is what matters.

---

### Lesson 8: Claude Can See Your Browser — Playwright MCP

Goal: have Claude look at their website and give visual feedback.
Artifact: Claude takes a screenshot of their site and suggests improvements based on what it sees.

Friction setup:
- Student wants Claude to check if their website looks good.
- But Claude can only read code — it can't "see" what the website looks like in a browser.
- "Wouldn't it be nice if Claude could open your website and look at it?"

Solution:
1. "We can give Claude a browser. It's called a 'plugin' — extra abilities you add."
2. Install Playwright MCP (tutor guides the exact command).
3. Start Claude Code, start the server in background or separate tab.
4. Tell Claude: "Open localhost:8080 in the browser, take a screenshot, and tell me what you think of the design."
5. Claude takes screenshot, analyzes it, suggests improvements.
6. "Now fix the issues you found."
7. Claude edits code, takes new screenshot, compares.

Features introduced: MCP (Model Context Protocol), Playwright, the concept of "plugins for Claude"
Aha moment: "Claude can see what I see — it opened a browser and looked at my website"

Teaching note: this lesson requires Playwright MCP to be pre-installed or easily installable. If setup is too complex, the tutor can demonstrate the concept and move on. The point is showing that Claude can be extended.

Progressive disclosure: only teach "MCP = plugin that gives Claude new abilities." Don't explain the protocol, transport types, or server architecture.

---

## Phase 3: Working Independently (Lessons 9-10)

### Lesson 9: Working Smarter — Context and Undo

Goal: understand and manage Claude's working memory.
Artifact: none — this is a productivity lesson. But practice on the existing website.

Friction setup:
- After many sessions, Claude may behave oddly, forget things mid-conversation, or respond slowly.
- Or simulate: have a long conversation, then ask Claude about something from early in the chat. It may not remember well.

Concepts to introduce through practice:
1. "/context" — "This shows how full Claude's memory is. Like a desk — when it's full, things fall off."
   - Run it. See the colored grid. Green = plenty of room. Red = almost full.
2. "/compact" — "This tidies up Claude's memory. It keeps the important stuff and forgets the chatter."
   - Run it when context is getting full.
   - "/compact focus on the website design changes" — tell Claude what to prioritize.
3. "/rewind" — "This is the undo button."
   - Make Claude do something, then rewind it.
   - "Every change Claude makes can be undone. You're always safe."
4. "/clear" — "Nuclear option. Forget everything, start fresh."
5. Session naming — "/rename my-website-v2", then "claude -c" to continue later.

Features introduced: /context, /compact, /rewind, /clear, /rename, session resuming
Aha moment: "I can undo anything Claude does — there's no way to break things permanently"

Teaching note: frame these as "tools you'll use when you need them" not "things you must memorize." The student should know they exist and roughly what they do.

---

### Lesson 10: Your Own Project — Putting It All Together

Goal: student builds something they actually want, with minimal guidance.
Artifact: a working project of their choice.

This is the "fading" lesson — the tutor steps back from copy-paste instructions to goal-based coaching.

Steps:
1. Ask: "What would you actually want to build? A tool for your business? A page for your company? A dashboard? A game?"
2. Together, plan the project folder: "cd ~/tutor-workspace/projects && mkdir [project-name] && cd [project-name]"
3. Create CLAUDE.md together — "What should Claude know about this project?"
4. Student works with Claude Code independently. Tutor watches, helps when stuck.
5. Tutor's role shifts:
   - Don't give step-by-step instructions
   - Instead: "What do you want to happen next?" and let them figure out how to ask Claude
   - Nudge toward features they've learned: "Remember, you can use /frontend-design for the styling"
   - Help debug when truly stuck

Features reinforced: everything from lessons 1-9, applied independently
Aha moment: "I built something real, for me, by myself"

---

## Phase 4: Beyond the Basics (Optional Advanced Lessons)

These are available if the student wants to go deeper. Each is self-contained.

### Lesson 11: Project Memory Mastery — Rules and Structure

When to teach: student has multiple projects and wants Claude to behave differently in each.

Concepts:
- .claude/rules/ — topic-specific instructions (one file per topic)
- CLAUDE.local.md — personal project preferences not shared with others
- Auto memory — Claude saves its own notes. "/memory" to view.
- Progressive disclosure pattern: short CLAUDE.md + detailed files linked with @path

### Lesson 12: Hooks — Automatic Quality Checks

When to teach: student keeps forgetting to test, lint, or check something after Claude makes changes.

Concepts:
- What hooks are: "automatic rules that always run — Claude can't forget them"
- PostToolUse hook: auto-run tests after every file edit
- Stop hook: "don't let Claude finish until tests pass"
- /hooks command for interactive setup

### Lesson 13: Custom Agents — Specialist Assistants

When to teach: student wants Claude to do different types of work (review, build, test) and wants each type done with specific instructions.

Concepts:
- Subagents: "specialists inside Claude — a reviewer, a tester, each focused"
- Creating a simple agent: .claude/agents/reviewer.md
- Tools restriction: "the reviewer can read but not edit"
- /agents command

### Lesson 14: Connecting Claude to Services — More MCP

When to teach: student wants Claude to interact with GitHub, databases, Notion, etc.

Concepts:
- MCP servers for specific services (GitHub, Notion, databases)
- "claude mcp add" for installation
- /mcp for authentication and management
- What MCP makes possible: "Claude can now read your GitHub issues"

### Lesson 15: Permissions and Safety

When to teach: student is comfortable and wants to control what Claude can/cannot do.

Concepts:
- Permission modes (plan mode, acceptEdits, bypass)
- Shift+Tab to cycle modes
- Fine-grained rules: allow specific commands, deny dangerous ones
- /permissions to view and manage

---

## Feature Introduction Timeline

Summary of when each Claude Code feature is first introduced:

| Lesson | Features Introduced |
|--------|-------------------|
| 1 | Terminal: ls, cd, mkdir, Tab, cd ~ |
| 2 | claude command, /exit, running code, project folders |
| 3 | The iterate loop (build > test > modify) |
| 4 | http server, viewing locally, design iteration |
| 5 | CLAUDE.md, /init, /memory |
| 6 | Skills (invoking), /help |
| 7 | Custom commands/skills (creating) |
| 8 | MCP (Playwright), concept of plugins |
| 9 | /context, /compact, /rewind, /clear, /rename, session resume |
| 10 | Independent application of all above |
| 11+ | Rules, hooks, agents, more MCP, permissions |

---

## Scaffolding Progression

How instruction style changes across lessons:

| Lessons | Instruction Style | Example |
|---------|------------------|---------|
| 1-2 | Full scaffold — exact commands | "Type exactly this: cd projects" |
| 3-4 | Partial scaffold — goal + hints | "Create a new project folder for tic-tac-toe, then start Claude Code" |
| 5-7 | Guided discovery — friction + solution | "Notice what happened? Claude forgot. Let's fix that." |
| 8-9 | Feature introduction — demo + practice | "Watch this... now you try" |
| 10 | Goal only — student drives | "What do you want to build? Go." |
| 11+ | On-demand — student asks, tutor helps | Reactive coaching |

---

## Notes for Tutor Implementation

- This curriculum is a GUIDE. The tutor should move fluidly based on student pace.
- Lessons 5-8 all use the website project to reduce cognitive load (familiar context).
- If a student asks about a feature before its lesson, teach it right then — don't defer.
- Phase 4 lessons are modular — teach in any order based on student need.
- The friction > solution pattern is critical: student must FEEL the problem before learning the solution.
- After lesson 4, every lesson should start with "remember your website project?" to maintain continuity.
