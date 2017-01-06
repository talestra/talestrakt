package com.talestra.rhcommon.time

import java.util.*

interface Updatable {
	fun update(dtMs: Int): Unit
}

open class UpdatableGroup : Updatable {
	private val updatables = ArrayList<Updatable>()

	fun add(updatable: Updatable) = updatables.add(updatable)
	fun remove(updatable: Updatable) = updatables.remove(updatable)
	fun removeAll() = updatables.clear()

	override fun update(dtMs: Int) {
		for (child in updatables.toList()) child.update(dtMs)
	}
}
